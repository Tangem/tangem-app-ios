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
    private let _selectedValidator = CurrentValueSubject<LoadingValue<ValidatorInfo>, Never>(.loading)

    private let _transaction = CurrentValueSubject<LoadingValue<StakingTransactionInfo>?, Never>(.none)
    private let _transactionTime = PassthroughSubject<Date?, Never>()

    // MARK: - Dependencies

    // MARK: - Private injections

    private let stakingManager: StakingManager
    private let sendTransactionDispatcher: SendTransactionDispatcher
    private let feeTokenItem: TokenItem

    private var bag: Set<AnyCancellable> = []

    init(
        stakingManager: StakingManager,
        sendTransactionDispatcher: SendTransactionDispatcher,
        feeTokenItem: TokenItem
    ) {
        self.stakingManager = stakingManager
        self.sendTransactionDispatcher = sendTransactionDispatcher
        self.feeTokenItem = feeTokenItem

        bind()
    }
}

// MARK: - Bind

private extension StakingModel {
    func bind() {
        Publishers
            .CombineLatest(
                _amount.compactMap { $0?.crypto },
                _selectedValidator.compactMap { $0.value }
            )
            .setFailureType(to: Error.self)
            .withWeakCaptureOf(self)
            .tryAsyncMap { model, args in
                let (amount, validator) = args
                model._transaction.send(.loading)

                return try await model.stakingManager.transaction(
                    action: .stake(amount: amount, validator: validator.address)
                )
            }
            .mapToResult()
            .withWeakCaptureOf(self)
            .sink { model, result in
                switch result {
                case .success(let transaction):
                    model._transaction.send(.loaded(transaction))
                case .failure(let error):
                    AppLog.shared.error(error)
                    model._transaction.send(.failedToLoad(error: error))
                }
            }
            .store(in: &bag)
    }

    func mapToSendFee(transaction: LoadingValue<StakingTransactionInfo>?) -> SendFee {
        var value = transaction?.mapValue { tx in
            Fee(.init(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: tx.fee))
        }

        return SendFee(option: .market, value: value ?? .failedToLoad(error: CommonError.noData))
    }
}

// MARK: - Send

private extension StakingModel {
    private func send() -> AnyPublisher<SendTransactionDispatcherResult, Never> {
        guard let transaction = _transaction.value?.value else {
            return .just(output: .transactionNotFound)
        }

        return sendTransactionDispatcher
            .send(transaction: .staking(transaction))
            .withWeakCaptureOf(self)
            .compactMap { sender, result in
                sender.proceed(transaction: transaction, result: result)
                return result
            }
            .eraseToAnyPublisher()
    }

    private func proceed(transaction: StakingTransactionInfo, result: SendTransactionDispatcherResult) {
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

// MARK: - SendFeeLoader

extension StakingModel: SendFeeLoader {
    func updateFees() {}
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
        return mapToSendFee(transaction: _transaction.value)
    }

    var selectedFeePublisher: AnyPublisher<SendFee, Never> {
        _transaction
            .withWeakCaptureOf(self)
            .map { model, transaction in
                model.mapToSendFee(transaction: transaction)
            }
            .eraseToAnyPublisher()
    }

    var feesPublisher: AnyPublisher<[SendFee], Never> {
        .just(output: [selectedFee])
    }

    var cryptoAmountPublisher: AnyPublisher<Decimal, Never> {
        _amount.compactMap { $0?.crypto }.eraseToAnyPublisher()
    }

    var destinationAddressPublisher: AnyPublisher<String?, Never> {
        assertionFailure("We don't have destination in staking")
        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - SendFeeOutput

extension StakingModel: SendFeeOutput {
    func feeDidChanged(fee: SendFee) {
        assertionFailure("We can not change fee in staking")
    }
}

// MARK: - SendSummaryInput, SendSummaryOutput

extension StakingModel: SendSummaryInput, SendSummaryOutput {
    var transactionPublisher: AnyPublisher<SendTransactionType?, Never> {
        _transaction
            .map { $0?.value.flatMap { .staking($0) } }
            .eraseToAnyPublisher()
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
        send()
    }
}

// MARK: - StakingNotificationManagerInput

extension StakingModel: StakingNotificationManagerInput {
    var stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never> {
        stakingManager.statePublisher
    }
}
