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
    private let _fee = CurrentValueSubject<LoadingValue<Decimal>?, Never>(.none)

    // MARK: - Dependencies

    // MARK: - Private injections

    private let stakingManager: StakingManager
    private let sendTransactionDispatcher: SendTransactionDispatcher
    private let validator: String
    private let amountTokenItem: TokenItem
    private let feeTokenItem: TokenItem
    private let stakingMapper: StakingMapper

    private var bag: Set<AnyCancellable> = []

    init(
        stakingManager: StakingManager,
        sendTransactionDispatcher: SendTransactionDispatcher,
        validator: String,
        amountTokenItem: TokenItem,
        feeTokenItem: TokenItem
    ) {
        self.stakingManager = stakingManager
        self.sendTransactionDispatcher = sendTransactionDispatcher
        self.validator = validator
        self.amountTokenItem = amountTokenItem
        self.feeTokenItem = feeTokenItem
        stakingMapper = StakingMapper(
            amountTokenItem: amountTokenItem,
            feeTokenItem: feeTokenItem
        )

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

        _amount.compactMap { $0?.crypto }
            .setFailureType(to: Error.self)
            .withWeakCaptureOf(self)
            .tryAsyncMap { model, amount in
                model._fee.send(.loading)

                let action = StakingAction(amount: amount, validator: model.validator, type: .unstake)
                return try await model.stakingManager.estimateFee(action: action)
            }
            .mapToResult()
            .withWeakCaptureOf(self)
            .sink { model, result in
                switch result {
                case .success(let fee):
                    model._fee.send(.loaded(fee))
                case .failure(let error):
                    AppLog.shared.error(error)
                    model._fee.send(.failedToLoad(error: error))
                }
            }
            .store(in: &bag)
    }

    func update(state: StakingManagerState) {
        switch state {
        case .staked(let staked):
            guard let balance = staked.balance(validator: validator) else {
                assertionFailure("The balance for validator \(validator) not found")
                return
            }

            let fiat = amountTokenItem.currencyId.flatMap { BalanceConverter().convertToFiat(balance.blocked, currencyId: $0) }
            _amount.send(.init(type: .typical(crypto: balance.blocked, fiat: fiat)))
        default:
            assertionFailure("The state \(state) doesn't support in this UnstakingModel")
        }
    }

    func mapToSendFee(_ fee: LoadingValue<Decimal>?) -> SendFee {
        let value = fee?.mapValue { fee in
            Fee(.init(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: fee))
        }
        return SendFee(option: .market, value: value ?? .failedToLoad(error: CommonError.noData))
    }
}

// MARK: - Send

private extension UnstakingModel {
    private func send() -> AnyPublisher<SendTransactionDispatcherResult, Never> {
        _amount
            .compactMap { $0?.crypto }
            .setFailureType(to: Error.self)
            .withWeakCaptureOf(self)
            .tryAsyncMap { args in
                let (model, amount) = args
                let action = StakingAction(amount: amount, validator: model.validator, type: .unstake)
                let transactionInfo = try await model.stakingManager.transaction(action: action)
                return (transactionInfo, amount)
            }
            .withWeakCaptureOf(self)
            .flatMap { args in
                let (model, (transactionInfo, amount)) = args
                let transaction = model.stakingMapper.mapToStakeKitTransaction(transactionInfo: transactionInfo, value: amount)

                return model.sendTransactionDispatcher
                    .sendPublisher(transaction: .staking(transaction))
                    .handleEvents(receiveOutput: { [weak model] output in
                        model?.proceed(transaction: transactionInfo, result: output)
                    })
            }
            .replaceError(with: .transactionNotFound) // TODO: refactor combine/concurrency
            .eraseToAnyPublisher()
    }

    private func proceed(transaction: StakingTransactionInfo, result: SendTransactionDispatcherResult) {
        switch result {
        case .informationRelevanceServiceError,
             .informationRelevanceServiceFeeWasIncreased,
             .transactionNotFound,
             .demoAlert,
             .userCancelled,
             .sendTxError,
             .stakingUnsupported:
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
        mapToSendFee(_fee.value)
    }

    var selectedFeePublisher: AnyPublisher<SendFee, Never> {
        _fee
            .withWeakCaptureOf(self)
            .map { model, fee in
                model.mapToSendFee(fee)
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
            .withWeakCaptureOf(self)
            .map { model, txValue in
                guard let tx = txValue?.value else {
                    return nil
                }

                let stakeKitTx = model.stakingMapper.mapToStakeKitTransaction(transactionInfo: tx, value: 0)
                return SendTransactionType.staking(stakeKitTx)
            }
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
