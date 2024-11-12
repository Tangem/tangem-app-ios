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
    func openOnrampSettingsView()
}

class OnrampModel {
    // MARK: - Data

    private let _currency: CurrentValueSubject<LoadingValue<OnrampFiatCurrency>, Never>
    private let _amount: CurrentValueSubject<SendAmount?, Never> = .init(.none)
    private let _selectedOnrampProvider: CurrentValueSubject<LoadingValue<OnrampProvider>?, Never> = .init(.none)
    private let _selectedOnrampPaymentMethod: CurrentValueSubject<OnrampPaymentMethod?, Never> = .init(.none)
    private let _onrampProviders: CurrentValueSubject<[OnrampProvider], Never> = .init([])
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
        // Handle the settings changes
        onrampRepository
            .preferenceCurrencyPublisher
            .sink { [weak self] currency in
                self?.preferenceDidChange(currency: currency)
            }
            .store(in: &bag)

        _amount
            .sink { [weak self] amount in
                self?.updateQuotes(amount: amount?.fiat)
            }
            .store(in: &bag)
    }

    func preferenceDidChange(currency: OnrampFiatCurrency?) {
        guard let country = onrampRepository.preferenceCountry, let currency else {
            startTask {
                try await $0.initiateCountryDefinition()
            }
            return
        }

        // Update amount UI
        _currency.send(.loaded(currency))

        startTask {
            try await $0.updateProviders(country: country, currency: currency)
        }
    }

    func initiateCountryDefinition() async throws {
        let country = try await onrampManager.initialSetupCountry()

        // Update amount UI
        _currency.send(.loaded(country.currency))

        // We have to show confirmation bottom sheet
        await runOnMain {
            router?.openOnrampCountryBottomSheet(country: country)
        }
    }

    func updateProviders(country: OnrampCountry, currency: OnrampFiatCurrency) async throws {
        let request = makeOnrampPairRequestItem(country: country, currency: currency)
        // TODO: Check the providers is empty
        _ = try await onrampManager.setupProviders(request: request)
    }

    func updateQuotes(amount: Decimal?) {
        guard let amount else {
            _selectedOnrampProvider.send(.none)
            // Clear onrampManager
            return
        }

        _selectedOnrampProvider.send(.loading)
        startTask { model in
            let providers = try await model.onrampManager.setupQuotes(amount: amount)
            model._onrampProviders.send(providers)
        }
    }
}

// MARK: - Helpers

private extension OnrampModel {
    func makeOnrampPairRequestItem(country: OnrampCountry, currency: OnrampFiatCurrency) -> OnrampPairRequestItem {
        OnrampPairRequestItem(fiatCurrency: currency, country: country, destination: walletModel)
    }

    func startTask(code: @escaping (OnrampModel) async throws -> Void) {
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
}

// MARK: - Buy

private extension OnrampModel {
    func send() async throws -> TransactionDispatcherResult {
        do {
            let result = TransactionDispatcherResult(hash: "", url: nil, signerType: "")
            proceed(result: result)
            return result
        } catch let error as TransactionDispatcherResult.Error {
            proceed(error: error)
            throw error
        } catch {
            throw TransactionDispatcherResult.Error.loadTransactionInfo(error: error)
        }
    }

    func proceed(result: TransactionDispatcherResult) {
        _transactionTime.send(Date())
    }

    func proceed(error: TransactionDispatcherResult.Error) {
        switch error {
        case .demoAlert,
             .userCancelled,
             .informationRelevanceServiceError,
             .informationRelevanceServiceFeeWasIncreased,
             .transactionNotFound,
             .loadTransactionInfo:
            break
        case .sendTxError:
            break
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

    var onrampProvidersPublisher: AnyPublisher<[OnrampProvider], Never> {
        _onrampProviders.eraseToAnyPublisher()
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
    var selectedOnrampPaymentMethod: OnrampPaymentMethod? {
        _selectedOnrampPaymentMethod.value
    }

    var selectedOnrampPaymentMethodPublisher: AnyPublisher<OnrampPaymentMethod?, Never> {
        _selectedOnrampPaymentMethod.eraseToAnyPublisher()
    }
}

// MARK: - OnrampPaymentMethodsOutput

extension OnrampModel: OnrampPaymentMethodsOutput {
    func userDidSelect(paymentMethod: OnrampPaymentMethod) {
        _selectedOnrampPaymentMethod.send(paymentMethod)
    }
}

// MARK: - OnrampInput

extension OnrampModel: OnrampInput {}

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
        _isLoading.eraseToAnyPublisher()
    }
}

// MARK: - SendBaseOutput

extension OnrampModel: SendBaseOutput {
    func performAction() async throws -> TransactionDispatcherResult {
        _isLoading.send(true)
        defer { _isLoading.send(false) }

        return try await send()
    }
}

// MARK: - OnrampBaseDataBuilderInput

extension OnrampModel: OnrampBaseDataBuilderInput {}

enum OnrampModelError: String, LocalizedError {
    case countryNotFound
    case currencyNotFound

    var errorDescription: String? { rawValue }
}
