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
    func openWebView(url: URL, success: @escaping () -> Void)
    func openFinishStep()
}

class OnrampModel {
    // MARK: - Data

    private let _currency: CurrentValueSubject<LoadingValue<OnrampFiatCurrency>, Never>
    private let _amount: CurrentValueSubject<SendAmount?, Never> = .init(.none)
    private let _selectedOnrampProvider: CurrentValueSubject<LoadingValue<OnrampProvider>?, Never> = .init(.none)
    private let _onrampProviders: CurrentValueSubject<LoadingValue<ProvidersList>?, Never> = .init(.none)
    private let _isLoading: CurrentValueSubject<Bool, Never> = .init(false)
    private let _transactionTime = PassthroughSubject<Date?, Never>()

    // MARK: - Dependencies

    weak var router: OnrampModelRoutable?
    weak var alertPresenter: SendViewAlertPresenter?

    // MARK: - Private injections

    private let walletModel: WalletModel
    private let onrampManager: OnrampManager
    private let onrampRepository: OnrampRepository

    private var task: Task<Void, Never>?
    private var bag: Set<AnyCancellable> = []

    init(
        walletModel: WalletModel,
        onrampManager: OnrampManager,
        onrampRepository: OnrampRepository
    ) {
        self.walletModel = walletModel
        self.onrampManager = onrampManager
        self.onrampRepository = onrampRepository

        _currency = .init(
            onrampRepository.preferenceCurrency.map { .loaded($0) } ?? .loading
        )

        bind()
    }
}

// MARK: - Bind

private extension OnrampModel {
    func bind() {
        _amount
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink { model, amount in
                model.updateQuotes(amount: amount?.fiat)
            }
            .store(in: &bag)

        // Handle the settings changes
        onrampRepository
            .preferenceCurrencyPublisher
            .removeDuplicates()
            .sink { [weak self] currency in
                self?.preferenceDidChange(currency: currency)
            }
            .store(in: &bag)
    }

    func updateProviders(country: OnrampCountry, currency: OnrampFiatCurrency) {
        mainTask(keeper: _onrampProviders.send) {
            $0._onrampProviders.send(.loading)

            let request = $0.makeOnrampPairRequestItem(country: country, currency: currency)
            try await $0.onrampManager.setupProviders(request: request)
            try Task.checkCancellation()

            return await $0.onrampManager.providers
        }
    }

    func updateQuotes(amount: Decimal?) {
        guard _onrampProviders.value?.value?.hasProviders() == true else {
            return
        }

        mainTask(keeper: _selectedOnrampProvider.send) {
            guard let amount else {
                // Clear onrampManager
                try await $0.onrampManager.setupQuotes(amount: .none)
                return .none
            }

            $0._selectedOnrampProvider.send(.loading)

            try await $0.onrampManager.setupQuotes(amount: amount)
            try Task.checkCancellation()

            return await $0.onrampManager.selectedProvider
        }
    }

    func updatePaymentMethod(method: OnrampPaymentMethod) {
        mainTask(keeper: _selectedOnrampProvider.send) {
            await $0.onrampManager.updatePaymentMethod(paymentMethod: method)

            return await $0.onrampManager.selectedProvider
        }
    }
}

// MARK: - Preference bindings

private extension OnrampModel {
    func preferenceDidChange(currency: OnrampFiatCurrency?) {
        guard let country = onrampRepository.preferenceCountry, let currency else {
            TangemFoundation.runTask(in: self) {
                await $0.initiateCountryDefinition()
            }
            return
        }

        // Update amount UI
        _currency.send(.loaded(currency))

        updateProviders(country: country, currency: currency)
    }

    func initiateCountryDefinition() async {
        do {
            let country = try await onrampManager.initialSetupCountry()

            // Update amount UI
            _currency.send(.loaded(country.currency))

            // We have to show confirmation bottom sheet
            await runOnMain {
                router?.openOnrampCountryBottomSheet(country: country)
            }
        } catch {
            await runOnMain {
                alertPresenter?.showAlert(error.alertBinder)
            }
        }
    }
}

// MARK: - Helpers

private extension OnrampModel {
    func makeOnrampPairRequestItem(country: OnrampCountry, currency: OnrampFiatCurrency) -> OnrampPairRequestItem {
        OnrampPairRequestItem(fiatCurrency: currency, country: country, destination: walletModel)
    }

    func mainTask<T>(keeper: @escaping (LoadingValue<T>?) -> Void, load: @escaping (OnrampModel) async throws -> T?) {
        task = TangemFoundation.runTask(in: self) {
            do {
                if let value = try await load($0) {
                    keeper(.loaded(value))
                } else {
                    keeper(.none)
                }

            } catch _ as CancellationError {
                // Do nothing
            } catch {
                keeper(.failedToLoad(error: error))
            }
        }
    }
}

// MARK: - OnrampAmountInput

extension OnrampModel: OnrampAmountInput {
    var fiatCurrency: LoadingValue<OnrampFiatCurrency> {
        _currency.value
    }

    var fiatCurrencyPublisher: AnyPublisher<LoadingValue<OnrampFiatCurrency>, Never> {
        _currency.eraseToAnyPublisher()
    }
}

// MARK: - OnrampAmountOutput

extension OnrampModel: OnrampAmountOutput {
    func amountDidChanged(amount: SendAmount?) {
        _amount.send(amount)
    }
}

// MARK: - OnrampProvidersInput

extension OnrampModel: OnrampProvidersInput {
    var selectedOnrampProvider: OnrampProvider? {
        _selectedOnrampProvider.value?.value
    }

    var selectedOnrampProviderPublisher: AnyPublisher<LoadingValue<OnrampProvider>?, Never> {
        _selectedOnrampProvider.eraseToAnyPublisher()
    }

    var onrampProvidersPublisher: AnyPublisher<LoadingValue<ProvidersList>, Never> {
        _onrampProviders.compactMap { $0 }.eraseToAnyPublisher()
    }
}

// MARK: - OnrampProvidersOutput

extension OnrampModel: OnrampProvidersOutput {
    func userDidSelect(provider: OnrampProvider) {
        _selectedOnrampProvider.send(.loaded(provider))
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
        _onrampProviders.compactMap { $0?.value?.map(\.paymentMethod) }.eraseToAnyPublisher()
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
        DispatchQueue.main.async {
            self.router?.openWebView(url: data.widgetUrl) { [weak self] in
                self?._transactionTime.send(Date())
                self?.router?.openFinishStep()
            }
        }
    }
}

// MARK: - OnrampInput

extension OnrampModel: OnrampInput {
    var isValidToRedirectPublisher: AnyPublisher<Bool, Never> {
        _selectedOnrampProvider
            .compactMap { $0?.value?.manager.state.isReadyToBuy }
            .eraseToAnyPublisher()
    }
}

// MARK: - OnrampOutput

extension OnrampModel: OnrampOutput {}

// MARK: - SendAmountInput

extension OnrampModel: SendAmountInput {
    var amount: SendAmount? { _amount.value }

    var amountPublisher: AnyPublisher<SendAmount?, Never> {
        _amount.eraseToAnyPublisher()
    }
}

// MARK: - SendFinishInput

extension OnrampModel: SendFinishInput {
    var transactionSentDate: AnyPublisher<Date, Never> {
        _transactionTime.compactMap { $0 }.first().eraseToAnyPublisher()
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
    var errorPublisher: AnyPublisher<OnrampModelError?, Never> {
        Publishers
            .CombineLatest3(_currency, _onrampProviders, _selectedOnrampProvider)
            .map { currency, providers, provider -> OnrampModelError? in
                if let currencyError = currency.error {
                    return .loadingCountry(error: currencyError)
                }

                if let providersError = providers?.error {
                    return .loadingProviders(error: providersError)
                }

                if let error = provider?.value?.manager.state.error {
                    return .loadingQuotes(error: error.error)
                }

                return nil
            }
            .eraseToAnyPublisher()
    }

    func refreshError() {
        if case .failedToLoad = _currency.value {
            TangemFoundation.runTask(in: self) {
                await $0.initiateCountryDefinition()
            }
        }

        if case .failedToLoad = _onrampProviders.value,
           let country = onrampRepository.preferenceCountry,
           let currency = onrampRepository.preferenceCurrency {
            updateProviders(country: country, currency: currency)
        }

        if case .failed = _selectedOnrampProvider.value?.value?.manager.state {
            updateQuotes(amount: _amount.value?.fiat)
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

enum OnrampModelError: LocalizedError {
    case loadingCountry(error: Error)
    case loadingProviders(error: Error)
    case loadingQuotes(error: Error)

    var errorDescription: String? {
        switch self {
        case .loadingCountry(error: let error):
            "Failed to load country: \(error.localizedDescription)"
        case .loadingProviders(error: let error):
            "Failed to load providers: \(error.localizedDescription)"
        case .loadingQuotes(error: let error):
            "Failed to load quotes: \(error.localizedDescription))"
        }
    }
}
