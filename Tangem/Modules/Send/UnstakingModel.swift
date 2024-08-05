//
//  UnstakingModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import Combine
import BlockchainSdk

class UnstakingModel {
    // MARK: - Data

    private let _amount = CurrentValueSubject<SendAmount?, Never>(.none)
    private let _transaction = CurrentValueSubject<LoadingValue<StakingTransactionInfo>?, Never>(.none)
    private let _transactionTime = PassthroughSubject<Date?, Never>()

    // MARK: - Dependencies

    // MARK: - Private injections

    private let stakingManager: StakingManager
    private let sendTransactionDispatcher: SendTransactionDispatcher
    private let validator: String
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem

    private var bag: Set<AnyCancellable> = []

    init(
        stakingManager: StakingManager,
        sendTransactionDispatcher: SendTransactionDispatcher,
        validator: String,
        tokenItem: TokenItem,
        feeTokenItem: TokenItem
    ) {
        self.stakingManager = stakingManager
        self.sendTransactionDispatcher = sendTransactionDispatcher
        self.validator = validator
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem

        bind()
    }
}

// MARK: - Bind

private extension UnstakingModel {
    func bind() {
        stakingManager.statePublisher
            .withWeakCaptureOf(self)
            .sink { model, state in
                model.update(state: state)
            }
            .store(in: &bag)

        Just(validator) // TODO: Any input data (?)
            .setFailureType(to: Error.self)
            .withWeakCaptureOf(self)
            .tryAsyncMap { model, validator in
                model._transaction.send(.loading)

                return try await model.stakingManager.transaction(action: .unstake(validator: validator))
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

    func update(state: StakingManagerState) {
        switch state {
        case .staked(let balances, _):
            guard let balance = balances.first(where: { $0.validatorAddress == validator }) else {
                assertionFailure("The balance for validator \(validator) not found")
                return
            }

            let fiat = tokenItem.currencyId.flatMap { BalanceConverter().convertToFiat(balance.blocked, currencyId: $0) }
            _amount.send(.init(type: .typical(crypto: balance.blocked, fiat: fiat)))
        default:
            assertionFailure("The state \(state) doesn't support in this UnstakingModel")
        }
    }

    func mapToSendFee(transaction: LoadingValue<StakingTransactionInfo>?) -> SendFee {
        let value = transaction?.mapValue { tx in
            Fee(.init(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: tx.fee))
        }

        return SendFee(option: .market, value: value ?? .failedToLoad(error: CommonError.noData))
    }
}

// MARK: - Send

private extension UnstakingModel {
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

extension UnstakingModel: SendFeeLoader {
    func updateFees() {}
}

// MARK: - SendAmountInput

extension UnstakingModel: SendAmountInput {
    var amount: SendAmount? { _amount.value }

    var amountPublisher: AnyPublisher<SendAmount?, Never> {
        _amount.eraseToAnyPublisher()
    }
}

// MARK: - SendAmountOutput

extension UnstakingModel: SendAmountOutput {
    func amountDidChanged(amount: SendAmount?) {
        assertionFailure("We can not change amount in unstaking")
    }
}

// MARK: - SendFeeInput

extension UnstakingModel: SendFeeInput {
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

extension UnstakingModel: SendFeeOutput {
    func feeDidChanged(fee: SendFee) {
        assertionFailure("We can not change fee in staking")
    }
}

// MARK: - SendSummaryInput, SendSummaryOutput

extension UnstakingModel: SendSummaryInput, SendSummaryOutput {
    var transactionPublisher: AnyPublisher<SendTransactionType?, Never> {
        _transaction
            .map { $0?.value.flatMap { .staking($0) } }
            .eraseToAnyPublisher()
    }
}

// MARK: - SendFinishInput

extension UnstakingModel: SendFinishInput {
    var transactionSentDate: AnyPublisher<Date, Never> {
        _transactionTime.compactMap { $0 }.first().eraseToAnyPublisher()
    }
}

// MARK: - SendBaseInput, SendBaseOutput

extension UnstakingModel: SendBaseInput, SendBaseOutput {
    var isFeeIncluded: Bool { false }

    var isLoading: AnyPublisher<Bool, Never> {
        sendTransactionDispatcher.isSending
    }

    func sendTransaction() -> AnyPublisher<SendTransactionDispatcherResult, Never> {
        send()
    }
}

// MARK: - StakingNotificationManagerInput

extension UnstakingModel: StakingNotificationManagerInput {
    var stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never> {
        stakingManager.statePublisher
    }
}
