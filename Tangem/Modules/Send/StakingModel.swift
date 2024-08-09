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
import TangemFoundation

class StakingModel {
    // MARK: - Data

    private let _amount = CurrentValueSubject<SendAmount?, Never>(nil)
    private let _selectedValidator = CurrentValueSubject<LoadingValue<ValidatorInfo>, Never>(.loading)
    private let _estimatedFee = CurrentValueSubject<LoadingValue<Decimal>?, Never>(.none)
    private let _transactionTime = PassthroughSubject<Date?, Never>()
    private let _isLoading = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Dependencies

    // MARK: - Private injections

    private let stakingManager: StakingManager
    private let sendTransactionDispatcher: SendTransactionDispatcher
    private let feeTokenItem: TokenItem
    private let stakingMapper: StakingMapper

    private var estimatedFeeTask: Task<Void, Never>?
    private var sendTransactionTask: Task<Void, Never>?
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
        estimatedFeeTask?.cancel()

        estimatedFeeTask = runTask(in: self) { model in
            model._estimatedFee.send(.loading)

            do {
                let fee = try await model.stakingManager.estimateFee(
                    action: StakingAction(amount: amount, validator: validator, type: .stake)
                )
                model._estimatedFee.send(.loaded(fee))
            } catch {
                model._estimatedFee.send(.failedToLoad(error: error))
            }
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

private extension StakingModel {
    private func send() async throws -> SendTransactionDispatcherResult {
        guard let amount = _amount.value?.crypto else {
            throw StakingModelError.amountNotFound
        }

        guard let validator = _selectedValidator.value.value else {
            throw StakingModelError.amountNotFound
        }

        let action = StakingAction(amount: amount, validator: validator.address, type: .stake)
        let transactionInfo = try await stakingManager.transaction(action: action)
        let transaction = stakingMapper.mapToStakeKitTransaction(transactionInfo: transactionInfo, value: amount)

        do {
            let result = try await sendTransactionDispatcher.send(
                transaction: .staking(transactionId: transactionInfo.id, transaction: transaction)
            )
            proceed(result: result)
            return result
        } catch let error as SendTransactionDispatcherResult.Error {
            proceed(error: error)
            throw error
        } catch {
            throw error
        }
    }

    private func proceed(result: SendTransactionDispatcherResult) {
        _transactionTime.send(Date())
    }

    private func proceed(error: SendTransactionDispatcherResult.Error) {
        switch error {
        case .informationRelevanceServiceError,
             .informationRelevanceServiceFeeWasIncreased,
             .transactionNotFound,
             .stakingUnsupported,
             .demoAlert,
             .userCancelled,
             .sendTxError:
            // TODO: Add analytics
            break
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
        mapToSendFee(_estimatedFee.value)
    }

    var selectedFeePublisher: AnyPublisher<SendFee, Never> {
        _estimatedFee
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
    var isReadyToSendPublisher: AnyPublisher<Bool, Never> {
        _estimatedFee.map { $0?.value != nil }.eraseToAnyPublisher()
    }

    var summaryTransactionDataPublisher: AnyPublisher<SendSummaryTransactionData?, Never> {
        Publishers.CombineLatest(_amount, _estimatedFee)
            .map { amount, fee in
                guard let amount, let fee = fee?.value else {
                    return nil
                }

                return .staking(amount: amount, fee: fee)
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
        _isLoading.eraseToAnyPublisher()
    }

    func sendTransaction() async throws -> SendTransactionDispatcherResult {
        _isLoading.send(true)
        defer { _isLoading.send(false) }

        return try await send()
    }
}

// MARK: - StakingNotificationManagerInput

extension StakingModel: StakingNotificationManagerInput {
    var stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never> {
        stakingManager.statePublisher
    }
}

enum StakingModelError: Error {
    case amountNotFound
    case validatorNotFound
}
