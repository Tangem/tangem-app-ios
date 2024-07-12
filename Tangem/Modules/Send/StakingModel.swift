//
//  StakingModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 10.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import Combine
import BlockchainSdk

class StakingModel {
    // MARK: - Data

    private let _amount = CurrentValueSubject<SendAmount?, Never>(nil)
    private let _selectedFee = CurrentValueSubject<SendFee, Never>(.init(option: .market, value: .loading))
    private let _selectedValidator = CurrentValueSubject<LoadingValue<ValidatorInfo>, Never>(.loading)

    private let _transaction = CurrentValueSubject<BSDKTransaction?, Never>(nil)
    private let _transactionError = CurrentValueSubject<Error?, Never>(nil)
    private let _transactionTime = PassthroughSubject<Date?, Never>()

    // MARK: - Dependencies

    var informationRelevanceService: InformationRelevanceService!

    // MARK: - Private injections

    private let sendTransactionDispatcher: SendTransactionDispatcher

    init(sendTransactionDispatcher: SendTransactionDispatcher) {
        self.sendTransactionDispatcher = sendTransactionDispatcher
    }
}

// MARK: - Send

private extension StakingModel {
    private func sendIfInformationIsActual() -> AnyPublisher<SendTransactionDispatcherResult, Never> {
        if informationRelevanceService.isActual {
            return send()
        }

        return informationRelevanceService
            .updateInformation()
            .mapToResult()
            .withWeakCaptureOf(self)
            .flatMap { manager, result -> AnyPublisher<SendTransactionDispatcherResult, Never> in
                switch result {
                case .failure:
                    return .just(output: .informationRelevanceServiceError)
                case .success(.feeWasIncreased):
                    return .just(output: .informationRelevanceServiceFeeWasIncreased)
                case .success(.ok):
                    return manager.send()
                }
            }
            .eraseToAnyPublisher()
    }

    private func send() -> AnyPublisher<SendTransactionDispatcherResult, Never> {
        return .just(output: .demoAlert)
        // TODO: Stake flow
    }

    private func proceed(transaction: BSDKTransaction, result: SendTransactionDispatcherResult) {
        switch result {
        case .informationRelevanceServiceError,
             .informationRelevanceServiceFeeWasIncreased,
             .transactionNotFound,
             .demoAlert,
             .userCancelled,
             .sendTxError:
            // TODO: Add analytics
            break
        case .success:
            _transactionTime.send(Date())
        }
    }
}

// MARK: - SendAmountInput

extension StakingModel: SendAmountInput {
    var amount: SendAmount? { _amount.value }

    var amountPublisher: AnyPublisher<SendAmount?, Never> {
        _amount.eraseToAnyPublisher()
    }
}

// MARK: - SendAmountOutput

extension StakingModel: SendAmountOutput {
    func amountDidChanged(amount: SendAmount?) {
        _amount.send(amount)
    }
}

// MARK: - StakingValidatorsInput

extension StakingModel: StakingValidatorsInput {
    var selectedValidatorPublisher: AnyPublisher<TangemStaking.ValidatorInfo, Never> {
        _selectedValidator.compactMap { $0.value }.eraseToAnyPublisher()
    }
}

// MARK: - StakingValidatorsOutput

extension StakingModel: StakingValidatorsOutput {
    func userDidSelected(validator: TangemStaking.ValidatorInfo) {
        _selectedValidator.send(.loaded(validator))
    }
}

// MARK: - SendFeeInput

extension StakingModel: SendFeeInput {
    var selectedFee: SendFee {
        _selectedFee.value
    }

    var selectedFeePublisher: AnyPublisher<SendFee, Never> {
        _selectedFee.eraseToAnyPublisher()
    }

    var cryptoAmountPublisher: AnyPublisher<BlockchainSdk.Amount, Never> {
        assertionFailure("We can not calculate fee in staking")
        return Empty().eraseToAnyPublisher()
    }

    var destinationAddressPublisher: AnyPublisher<String?, Never> {
        assertionFailure("We can not calculate fee in staking")
        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - SendFeeOutput

extension StakingModel: SendFeeOutput {
    func feeDidChanged(fee: SendFee) {
        _selectedFee.send(fee)
    }
}

// MARK: - SendSummaryInput, SendSummaryOutput

extension StakingModel: SendSummaryInput, SendSummaryOutput {
    var transactionPublisher: AnyPublisher<BlockchainSdk.Transaction?, Never> {
        _transaction.eraseToAnyPublisher()
    }
}

// MARK: - SendFinishInput

extension StakingModel: SendFinishInput {
    var transactionSentDate: AnyPublisher<Date, Never> {
        _transactionTime.compactMap { $0 }.first().eraseToAnyPublisher()
    }
}

// MARK: - SendBaseInput, SendBaseOutput

extension StakingModel: SendBaseInput, SendBaseOutput {
    var isFeeIncluded: Bool { false }

    var isLoading: AnyPublisher<Bool, Never> {
        sendTransactionDispatcher.isSending
    }

    func sendTransaction() -> AnyPublisher<SendTransactionDispatcherResult, Never> {
        sendIfInformationIsActual()
    }
}
