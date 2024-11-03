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

protocol OnrampModelRoutable: AnyObject {
    func openOnrampCountryBottomSheet(country: OnrampCountry)
    func openOnrampCountrySelectorView()
    func openOnrampSettingsView()
}

class OnrampModel {
    // MARK: - Data

    private let _currency: CurrentValueSubject<OnrampFiatCurrency?, Never> = .init(nil)
    private let _amount: CurrentValueSubject<SendAmount?, Never> = .init(nil)
    private let _selectedQuote: CurrentValueSubject<OnrampQuote?, Never> = .init(nil)
    private let _transactionTime = PassthroughSubject<Date?, Never>()
    private let _state = CurrentValueSubject<State?, Never>(nil)

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
    }

    func preferenceDidChange(currency: OnrampFiatCurrency?) {
        guard let country = onrampRepository.preferenceCountry, let currency else {
            startTask(type: .country) {
                try await $0.initiateCountryDefinition()
            }
            return
        }

        // Update amount UI
        _currency.send(currency)

        startTask(type: .rates) {
            try await $0.updateProviders(country: country, currency: currency)
        }
    }

    func initiateCountryDefinition() async throws {
        let country = try await onrampManager.initialSetupCountry()

        // Update amount UI
        _currency.send(country.currency)

        // We have to show confirmation bottom sheet
        await runOnMain {
            router?.openOnrampCountryBottomSheet(country: country)
        }
    }

    func updateProviders(country: OnrampCountry, currency: OnrampFiatCurrency) async throws {
        let request = makeOnrampPairRequestItem(country: country, currency: currency)
        try await onrampManager.setupProviders(request: request)
    }
}

// MARK: - Helpers

private extension OnrampModel {
    func makeOnrampPairRequestItem(country: OnrampCountry, currency: OnrampFiatCurrency) -> OnrampPairRequestItem {
        OnrampPairRequestItem(fiatCurrency: currency, country: country, destination: walletModel)
    }

    func startTask(type: LoadingType, code: @escaping (OnrampModel) async throws -> Void) {
        task = runTask(in: self) { model in
            model._state.send(.loading(type))
            defer { model._state.send(.loaded) }

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

// MARK: - OnrampInput

extension OnrampModel: OnrampInput {
    var currencyPublisher: AnyPublisher<OnrampFiatCurrency, Never> {
        _currency.compactMap { $0 }.eraseToAnyPublisher()
    }

    var isLoadingRatesPublisher: AnyPublisher<Bool, Never> {
        _state.map { state in
            switch state {
            case .loading(.rates): true
            default: false
            }
        }.eraseToAnyPublisher()
    }

    var selectedQuotePublisher: AnyPublisher<OnrampQuote?, Never> {
        _selectedQuote.eraseToAnyPublisher()
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

// MARK: - SendAmountOutput

extension OnrampModel: SendAmountOutput {
    func amountDidChanged(amount: SendAmount?) {
        _amount.send(amount)
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
        _state.map { state in
            switch state {
            case .loading: true
            default: false
            }
        }.eraseToAnyPublisher()
    }
}

// MARK: - SendBaseOutput

extension OnrampModel: SendBaseOutput {
    func performAction() async throws -> TransactionDispatcherResult {
        _state.send(.loading(.redirectData))
        defer { _state.send(.loaded) }

        return try await send()
    }
}

// MARK: - OnrampBaseDataBuilderInput

extension OnrampModel: OnrampBaseDataBuilderInput {}

extension OnrampModel {
    enum State {
        case loading(LoadingType)
        case error(String)
        case loaded
    }

    enum LoadingType {
        case country
        case rates
        case redirectData
    }
}

enum OnrampModelError: String, LocalizedError {
    case countryNotFound
    case currencyNotFound

    var errorDescription: String? { rawValue }
}
