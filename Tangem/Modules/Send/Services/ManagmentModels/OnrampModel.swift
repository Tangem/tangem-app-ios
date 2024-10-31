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
    func openOnrampCountriesSelector()
    func openOnrampCountryBottomSheet(country: OnrampCountry)
}

class OnrampModel {
    // MARK: - Data

    private let _amount = CurrentValueSubject<SendAmount?, Never>(nil)
    private let _transactionTime = PassthroughSubject<Date?, Never>()
    private let _isLoading = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Dependencies

    weak var router: OnrampModelRoutable?
    weak var alertPresenter: SendViewAlertPresenter?

    // MARK: - Private injections

    private let onrampManager: OnrampManager

    private var task: Task<Void, Never>?
    private var bag: Set<AnyCancellable> = []

    init(onrampManager: OnrampManager) {
        self.onrampManager = onrampManager

        bind()
        updateCountry()
    }
}

// MARK: - Bind

private extension OnrampModel {
    func bind() {}

    func updateCountry() {
        task = runTask(in: self) { model in
            do {
                let country = try await model.onrampManager.getCountry()
                await runOnMain {
                    model.router?.openOnrampCountryBottomSheet(country: country)
                }
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
