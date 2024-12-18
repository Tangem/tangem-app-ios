//
//  OnrampModel.swift
//  TangemApp
//
//  Created by Sergey Balashov on 15.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import Combine
import TangemFoundation

protocol OnrampModelRoutable: AnyObject {
    func openOnrampCountryBottomSheet(country: OnrampCountry)
    func openOnrampCountrySelectorView()
    func openOnrampWebView(url: URL, onDismiss: @escaping () -> Void, onSuccess: @escaping () -> Void)
    func openFinishStep()
}

class OnrampModel {
    // MARK: - Data

    private let _currency: CurrentValueSubject<LoadingResult<OnrampFiatCurrency, Error>, Never>
    private let _amount: CurrentValueSubject<Decimal?, Never> = .init(.none)
    private let _onrampProviders: CurrentValueSubject<LoadingResult<ProvidersList, Error>?, Never> = .init(.none)
    private let _selectedOnrampProvider: CurrentValueSubject<LoadingResult<OnrampProvider, Never>?, Never> = .init(.none)
    private let _isLoading: CurrentValueSubject<Bool, Never> = .init(false)
    private let _transactionTime = PassthroughSubject<Date, Never>()
    private let _expressTransactionId = PassthroughSubject<String, Never>()

    // MARK: - Dependencies

    @Injected(\.onrampPendingTransactionsRepository) private var onrampPendingTransactionsRepository: OnrampPendingTransactionRepository
    weak var router: OnrampModelRoutable?
    weak var alertPresenter: SendViewAlertPresenter?

    // MARK: - Private injections

    private let userWalletId: String
    private let walletModel: WalletModel
    private let onrampManager: OnrampManager
    private let onrampDataRepository: OnrampDataRepository
    private let onrampRepository: OnrampRepository

    private var task: Task<Void, Never>?
    private var timerCancellable: AnyCancellable?

    private var bag: Set<AnyCancellable> = []

    init(
        userWalletId: String,
        walletModel: WalletModel,
        onrampManager: OnrampManager,
        onrampDataRepository: OnrampDataRepository,
        onrampRepository: OnrampRepository
    ) {
        self.userWalletId = userWalletId
        self.walletModel = walletModel
        self.onrampManager = onrampManager
        self.onrampDataRepository = onrampDataRepository
        self.onrampRepository = onrampRepository

        _currency = .init(
            onrampRepository.preferenceCurrency.map { .success($0) } ?? .loading
        )

        bind()
    }

    deinit {
        log("Deinit")
    }
}

// MARK: - Bind

private extension OnrampModel {
    func bind() {
        _amount
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink { model, amount in
                model.amountDidChange(amount: amount)
            }
            .store(in: &bag)

        // Handle the settings changes
        onrampRepository
            .preferencePublisher
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { model, preference in
                model.preferenceDidChange(country: preference.country, currency: preference.currency)
            }
            .store(in: &bag)

        // Only for analytics
        _selectedOnrampProvider
            .compactMap { $0?.value }
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { model, provider in
                switch provider.state {
                case .restriction(.tooSmallAmount):
                    Analytics.log(.onrampErrorMinAmount)
                case .restriction(.tooBigAmount):
                    Analytics.log(.onrampErrorMaxAmount)
                case .loaded:
                    Analytics.log(
                        event: .onrampProviderCalculated,
                        params: [
                            .token: model.walletModel.tokenItem.currencySymbol,
                            .provider: provider.provider.name,
                            .paymentMethod: provider.paymentMethod.name,
                        ]
                    )
                default:
                    break
                }
            }
            .store(in: &bag)

        _selectedOnrampProvider
            .withWeakCaptureOf(self)
            .sink { model, provider in
                let isSuccessfullyLoaded = provider?.value?.isSuccessfullyLoaded ?? false
                isSuccessfullyLoaded ? model.restartTimer() : model.stopTimer()
            }
            .store(in: &bag)
    }

    // MARK: - Timer

    func stopTimer() {
        log("Stop timer")
        timerCancellable?.cancel()
    }

    func restartTimer() {
        log("Restart timer")
        timerCancellable?.cancel()
        timerCancellable = Just(())
            .delay(for: 10, scheduler: DispatchQueue.global())
            .sink(receiveCompletion: { [weak self] completion in
                self?.log("Timer completion \(completion)")
            }, receiveValue: { [weak self] _ in
                self?.log("Timer will call autoupdate")
                self?.autoupdate()
            })
    }

    // MARK: - Providers list

    func updateProviders() async {
        guard let country = onrampRepository.preferenceCountry,
              let currency = onrampRepository.preferenceCurrency else {
            return
        }

        await updateProviders(country: country, currency: currency)
    }

    func updateProviders(country: OnrampCountry, currency: OnrampFiatCurrency) async {
        do {
            _onrampProviders.send(.loading)

            // In case when user change country / currency
            // And we have an amount in the filed
            // We'll show loading view like we load /quotes
            // When we load /pairs
            if hasAmount() {
                _selectedOnrampProvider.send(.loading)
            }

            let request = makeOnrampPairRequestItem(country: country, currency: currency)
            let providers = try await onrampManager.setupProviders(request: request)

            try Task.checkCancellation()
            _onrampProviders.send(.success(providers))

            try Task.checkCancellation()
            try await updateQuotes()
        } catch {
            _onrampProviders.send(.failure(error))
        }
    }

    func providersList() throws -> ProvidersList {
        guard let providers = _onrampProviders.value else {
            throw OnrampManagerError.providersIsEmpty
        }

        return try providers.get()
    }

    func hasAmount() -> Bool {
        _amount.value != nil
    }

    // MARK: - Quotes

    func amountDidChange(amount: Decimal?) {
        switch _onrampProviders.value {
        case .success(let list) where list.hasProviders():
            mainTask {
                try await $0.updateQuotes(amount: amount)
            }
        case .none, .loading, .success, .failure:
            // TODO: What we do when providers in the one of state above?
            return
        }
    }

    func updateQuotes() async throws {
        do {
            try await updateQuotes(amount: _amount.value)
        } catch OnrampManagerError.providersIsEmpty {
            _selectedOnrampProvider.send(.none)
        } catch {
            throw error
        }
    }

    func updateQuotes(amount: Decimal?) async throws {
        guard let amount, amount > 0 else {
            try await clearOnrampManager()
            return
        }

        try await updateOnrampManager(amount: amount)
    }

    func clearOnrampManager() async throws {
        let (list, provider) = try await onrampManager.setupQuotes(in: providersList(), amount: .clear)
        try Task.checkCancellation()
        _onrampProviders.send(.success(list))
        _selectedOnrampProvider.send(.success(provider))
    }

    func updateOnrampManager(amount: Decimal) async throws {
        _selectedOnrampProvider.send(.loading)
        let (list, provider) = try await onrampManager.setupQuotes(in: providersList(), amount: .amount(amount))
        try Task.checkCancellation()
        _onrampProviders.send(.success(list))
        _selectedOnrampProvider.send(.success(provider))
    }

    // MARK: - Payment method

    func updatePaymentMethod(method: OnrampPaymentMethod) {
        mainTask {
            let provider = try await $0.onrampManager.suggestProvider(in: $0.providersList(), paymentMethod: method)
            try Task.checkCancellation()
            $0._selectedOnrampProvider.send(.success(provider))
        }
    }
}

// MARK: - Preference bindings

private extension OnrampModel {
    func preferenceDidChange(country: OnrampCountry?, currency: OnrampFiatCurrency?) {
        guard let country, let currency else {
            TangemFoundation.runTask(in: self) {
                await $0.initiateCountryDefinition()
            }
            return
        }

        // Update amount UI
        _currency.send(.success(currency))

        mainTask {
            await $0.updateProvidersThroughCountryAvailabilityChecking(country: country, currency: currency)
        }
    }

    func updateProvidersThroughCountryAvailabilityChecking(country: OnrampCountry, currency: OnrampFiatCurrency) async {
        guard await checkCountryAvailability(country: country) else {
            return
        }

        await updateProviders(country: country, currency: currency)
    }

    func checkCountryAvailability(country: OnrampCountry) async -> Bool {
        do {
            let countries = try await onrampDataRepository.countries()
            guard let country = countries.first(where: { $0.identity == country.identity }) else {
                // For some reasons country disappeared from list
                // Try define again
                await initiateCountryDefinition()
                return false
            }

            if country.onrampAvailable {
                // All good
                return true
            }

            // Clear repo
            onrampRepository.updatePreference(country: nil, currency: nil)
            await runOnMain {
                router?.openOnrampCountryBottomSheet(country: country)
            }

            return false
        } catch {
            _currency.send(.failure(error))
            return false
        }
    }

    func initiateCountryDefinition() async {
        do {
            let country = try await onrampManager.initialSetupCountry()

            // Update amount UI
            _currency.send(.success(country.currency))

            // We have to show confirmation bottom sheet
            await runOnMain {
                router?.openOnrampCountryBottomSheet(country: country)
            }
        } catch {
            _currency.send(.failure(error))
        }
    }
}

// MARK: - Helpers

private extension OnrampModel {
    func makeOnrampPairRequestItem(country: OnrampCountry, currency: OnrampFiatCurrency) -> OnrampPairRequestItem {
        OnrampPairRequestItem(fiatCurrency: currency, country: country, destination: walletModel)
    }

    func mainTask(code: @escaping (OnrampModel) async throws -> Void) {
        task?.cancel()
        task = TangemFoundation.runTask(in: self) { model in
            do {
                try await code(model)
            } catch _ as CancellationError {
                // Do nothing
            } catch {
                await runOnMain {
                    model.alertPresenter?.showAlert(error.alertBinder)
                }
            }
        }
    }

    func autoupdate() {
        mainTask {
            $0.log("Call autoupdate")
            try await $0.autoupdateTask()
            $0.log("Autoupdate is finish")
        }
    }

    func autoupdateTask() async throws {
        guard _selectedOnrampProvider.value?.value?.isSuccessfullyLoaded == true else {
            log("Selected provider has an error. Do not start autoupdate")
            return
        }

        // Save for possible reselect
        let (list, provider) = try await onrampManager.setupQuotes(in: providersList(), amount: .same)
        try Task.checkCancellation()

        // Check after reloading
        guard _selectedOnrampProvider.value?.value?.isSuccessfullyLoaded == true else {
            log("Selected provider has a error. Will update to \(provider)")
            _onrampProviders.send(.success(list))
            _selectedOnrampProvider.send(.success(provider))
            return
        }

        // Push the same provider to notify all listeners
        _selectedOnrampProvider.resend()
        _onrampProviders.resend()
    }

    func log(_ message: String) {
        AppLog.shared.debug("[\(TangemFoundation.objectDescription(self))] \(message)")
    }
}

// MARK: - OnrampAmountInput

extension OnrampModel: OnrampAmountInput {
    var amountPublisher: AnyPublisher<Decimal?, Never> {
        _amount.eraseToAnyPublisher()
    }

    var fiatCurrency: OnrampFiatCurrency? {
        _currency.value.value
    }

    var fiatCurrencyPublisher: AnyPublisher<OnrampFiatCurrency?, Never> {
        _currency.map { $0.value }.eraseToAnyPublisher()
    }
}

// MARK: - OnrampAmountOutput

extension OnrampModel: OnrampAmountOutput {
    func amountDidChanged(fiat: Decimal?) {
        _amount.send(fiat)
    }
}

// MARK: - OnrampProvidersInput

extension OnrampModel: OnrampProvidersInput {
    var selectedOnrampProvider: OnrampProvider? {
        _selectedOnrampProvider.value?.value
    }

    var selectedOnrampProviderPublisher: AnyPublisher<LoadingResult<OnrampProvider, Never>?, Never> {
        _selectedOnrampProvider.eraseToAnyPublisher()
    }

    var onrampProvidersPublisher: AnyPublisher<LoadingResult<ProvidersList, Error>?, Never> {
        _onrampProviders.eraseToAnyPublisher()
    }
}

// MARK: - OnrampProvidersOutput

extension OnrampModel: OnrampProvidersOutput {
    func userDidSelect(provider: OnrampProvider) {
        _selectedOnrampProvider.send(.success(provider))
    }
}

// MARK: - OnrampPaymentMethodsInput

extension OnrampModel: OnrampPaymentMethodsInput {
    var selectedPaymentMethod: OnrampPaymentMethod? {
        _selectedOnrampProvider.value?.value?.paymentMethod
    }

    var selectedPaymentMethodPublisher: AnyPublisher<OnrampPaymentMethod?, Never> {
        _selectedOnrampProvider.map { $0?.value?.paymentMethod }.eraseToAnyPublisher()
    }

    var paymentMethodsPublisher: AnyPublisher<[OnrampPaymentMethod], Never> {
        _onrampProviders.compactMap {
            $0?.value?.filter { $0.hasSelectableProviders() }.map(\.paymentMethod)
        }.eraseToAnyPublisher()
    }
}

// MARK: - OnrampPaymentMethodsOutput

extension OnrampModel: OnrampPaymentMethodsOutput {
    func userDidSelect(paymentMethod: OnrampPaymentMethod) {
        updatePaymentMethod(method: paymentMethod)
    }
}

// MARK: - OnrampRedirectingInput

extension OnrampModel: OnrampRedirectingInput {}

// MARK: - OnrampRedirectingOutput

extension OnrampModel: OnrampRedirectingOutput {
    func redirectDataDidLoad(data: OnrampRedirectData) {
        guard let provider = selectedOnrampProvider else {
            assertionFailure("selectedOnrampProvider is unexpectedly nil")
            return
        }

        let txData = SentOnrampTransactionData(
            txId: data.txId,
            provider: provider.provider,
            destinationTokenItem: walletModel.tokenItem,
            date: Date(),
            fromAmount: data.fromAmount,
            fromCurrencyCode: data.fromCurrencyCode,
            externalTxId: data.externalTxId
        )

        onrampPendingTransactionsRepository
            .onrampTransactionDidSend(txData, userWalletId: userWalletId)

        stopTimer()
        DispatchQueue.main.async {
            self.router?.openOnrampWebView(url: data.widgetUrl, onDismiss: { [weak self] in
                self?.restartTimer()
            }, onSuccess: { [weak self] in
                self?._transactionTime.send(Date())
                self?._expressTransactionId.send(data.txId)
                self?.router?.openFinishStep()
            })
        }
    }
}

// MARK: - OnrampInput

extension OnrampModel: OnrampInput {
    var isValidToRedirectPublisher: AnyPublisher<Bool, Never> {
        _selectedOnrampProvider
            .map { $0?.value?.isSuccessfullyLoaded ?? false }
            .eraseToAnyPublisher()
    }
}

// MARK: - OnrampOutput

extension OnrampModel: OnrampOutput {}

// MARK: - SendFinishInput

extension OnrampModel: SendFinishInput {
    var transactionSentDate: AnyPublisher<Date, Never> {
        _transactionTime.first().eraseToAnyPublisher()
    }
}

// MARK: - OnrampStatusInput

extension OnrampModel: OnrampStatusInput {
    var expressTransactionId: AnyPublisher<String, Never> {
        _expressTransactionId.first().eraseToAnyPublisher()
    }
}

// MARK: - SendBaseInput

extension OnrampModel: SendBaseInput {
    var actionInProcessing: AnyPublisher<Bool, Never> {
        Publishers
            .Merge(_isLoading, _currency.map { $0.isLoading })
            .eraseToAnyPublisher()
    }
}

// MARK: - SendBaseOutput

extension OnrampModel: SendBaseOutput {
    func performAction() async throws -> TransactionDispatcherResult {
        assertionFailure("OnrampModel doesn't support the send transaction action")
        throw TransactionDispatcherResult.Error.actionNotSupported
    }
}

// MARK: - OnrampNotificationManagerInput

extension OnrampModel: OnrampNotificationManagerInput {
    var errorPublisher: AnyPublisher<Error?, Never> {
        let currencyErrorPublisher = _currency
            .filter { !$0.isLoading }
            .map { $0.error }

        let onrampProvidersErrorPublisher = _onrampProviders
            .compactMap { $0 }
            .filter { !$0.isLoading }
            .map { $0.error }

        let selectedOnrampProviderErrorPublisher = _selectedOnrampProvider
            .compactMap { $0 }
            // Here we clear error on `loading` state
            // Because we have the LoadingView
            .map { $0?.value?.error }

        return Publishers.Merge3(
            currencyErrorPublisher,
            onrampProvidersErrorPublisher,
            selectedOnrampProviderErrorPublisher
        )
        .eraseToAnyPublisher()
    }

    func refreshError() {
        if case .failure = _currency.value {
            TangemFoundation.runTask(in: self) {
                if let country = $0.onrampRepository.preferenceCountry,
                   let currency = $0.onrampRepository.preferenceCurrency {
                    await $0.updateProvidersThroughCountryAvailabilityChecking(country: country, currency: currency)
                } else {
                    await $0.initiateCountryDefinition()
                }
            }
        }

        if case .failure = _onrampProviders.value {
            mainTask {
                await $0.updateProviders()
            }
        }

        if case .failed = _selectedOnrampProvider.value?.value?.state {
            mainTask {
                try await $0.updateQuotes()
            }
        }
    }
}

// MARK: - NotificationTapDelegate

extension OnrampModel: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .refresh:
            refreshError()
        default:
            assertionFailure("Action not supported: \(action)")
        }
    }
}
