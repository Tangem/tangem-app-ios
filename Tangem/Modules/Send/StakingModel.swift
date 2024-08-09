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
    private let _fee = CurrentValueSubject<LoadingValue<Decimal>?, Never>(.none)

    // MARK: - Dependencies

    // MARK: - Private injections

    private let stakingManager: StakingManager
    private let sendTransactionDispatcher: SendTransactionDispatcher
    private let feeTokenItem: TokenItem
    private let stakingMapper: StakingMapper

    private var bag: Set<AnyCancellable> = []

    init(
        stakingManager: StakingManager,
        sendTransactionDispatcher: SendTransactionDispatcher,
        amountTokenItem: TokenItem,
        feeTokenItem: TokenItem
    ) {
        self.stakingManager = stakingManager
        self.sendTransactionDispatcher = sendTransactionDispatcher
        self.feeTokenItem = feeTokenItem
        stakingMapper = StakingMapper(
            amountTokenItem: amountTokenItem,
            feeTokenItem: feeTokenItem
        )

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
            .sink { [weak self] amount, validator in
                self?.estimateFee(amount: amount, validator: validator.address)
            }
            .store(in: &bag)
    }

    private func estimateFee(amount: Decimal, validator: String) {
        runTask(in: self) { model in
            await model.updateEstimateFee(.loading)
            do {
                let fee = try await model.stakingManager.estimateFee(
                    action: StakingAction(amount: amount, validator: validator, type: .stake)
                )
                await model.updateEstimateFee(.loaded(fee))
            } catch {
                await model.updateEstimateFee(.failedToLoad(error: error))
            }
        }
    }

    @MainActor
    private func updateEstimateFee(_ result: LoadingValue<Decimal>) {
        _fee.send(result)
    }

    func mapToSendFee(_ fee: LoadingValue<Decimal>?) -> SendFee {
        let value = fee?.mapValue { fee in
            Fee(.init(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: fee))
        }
        return SendFee(option: .market, value: value ?? .failedToLoad(error: CommonError.noData))
    }
}

// MARK: - Send

private extension StakingModel {
    private func send() -> AnyPublisher<SendTransactionDispatcherResult, Never> {
        Publishers
            .CombineLatest(
                _amount.compactMap { $0?.crypto },
                _selectedValidator.compactMap { $0.value }
            )
            .setFailureType(to: Error.self)
            .withWeakCaptureOf(self)
            .tryAsyncMap { args in
                let (model, (amount, validator)) = args
                let action = StakingAction(amount: amount, validator: validator.address, type: .stake)
                let transactionInfo = try await model.stakingManager.transaction(action: action)
                return (transactionInfo, amount)
            }
            .withWeakCaptureOf(self)
            .flatMap { args in
                let (model, (transactionInfo, amount)) = args
                let transaction = model.stakingMapper.mapToStakeKitTransaction(transactionInfo: transactionInfo, value: 0)
                return model.sendTransactionDispatcher
                    .sendPublisher(transaction: .staking(transaction))
            }
            .handleEvents(receiveOutput: { [weak self] output in
                self?.proceed(result: output)
            })
            .replaceError(with: .transactionNotFound) // TODO: refactor combine/concurrency
            .eraseToAnyPublisher()
    }

    private func proceed(result: SendTransactionDispatcherResult) {
        switch result {
        case .informationRelevanceServiceError,
             .informationRelevanceServiceFeeWasIncreased,
             .transactionNotFound,
             .stakingUnsupported,
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

extension StakingModel: SendFeeOutput {
    func feeDidChanged(fee: SendFee) {
        assertionFailure("We can not change fee in staking")
    }
}

// MARK: - SendSummaryInput, SendSummaryOutput

extension StakingModel: SendSummaryInput, SendSummaryOutput {
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
