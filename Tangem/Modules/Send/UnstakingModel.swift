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

    private let _state = CurrentValueSubject<LoadingValue<State>?, Never>(.none)
    private let _transactionTime = PassthroughSubject<Date?, Never>()
    private let _isLoading = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Private injections

    private let stakingManager: StakingManager
    private let sendTransactionDispatcher: SendTransactionDispatcher
    private let balanceInfo: StakingBalanceInfo
    private let amountTokenItem: TokenItem
    private let feeTokenItem: TokenItem
    private let stakingMapper: StakingMapper

    private var estimatedFeeTask: Task<Void, Never>?
    private var bag: Set<AnyCancellable> = []

    init(
        stakingManager: StakingManager,
        sendTransactionDispatcher: SendTransactionDispatcher,
        balanceInfo: StakingBalanceInfo,
        amountTokenItem: TokenItem,
        feeTokenItem: TokenItem
    ) {
        self.stakingManager = stakingManager
        self.sendTransactionDispatcher = sendTransactionDispatcher
        self.balanceInfo = balanceInfo
        self.amountTokenItem = amountTokenItem
        self.feeTokenItem = feeTokenItem
        stakingMapper = StakingMapper(
            amountTokenItem: amountTokenItem,
            feeTokenItem: feeTokenItem
        )

        updateState()
    }
}

// MARK: - Public

extension UnstakingModel {
    var state: AnyPublisher<UnstakingModel.State, Never> {
        _state.compactMap { $0?.value }.eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension UnstakingModel {
    func updateState() {
        estimatedFeeTask?.cancel()

        estimatedFeeTask = runTask(in: self) { model in
            do {
                model._state.send(.loading)
                try await model._state.send(.loaded(model.state()))
            } catch {
                AppLog.shared.error(error)
                model._state.send(.failedToLoad(error: error))
            }
        }
    }

    func state() async throws -> State {
        let action = try stakingAction()
        let fee = try await stakingManager.estimateFee(action: action)
        switch action.type {
        case .unstake:
            return .unstaking(fee: fee)
        case .pending(.withdraw):
            return .withdraw(fee: fee)
        case .stake:
            throw UnstakingModelError.notSupported(
                "UnstakingModel doesn't support actionType: \(action.type)"
            )
        }
    }

    func mapToSendFee(_ fee: LoadingValue<State>?) -> SendFee {
        let value = fee?.mapValue { state in
            Fee(.init(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: state.fee))
        }
        return SendFee(option: .market, value: value ?? .failedToLoad(error: CommonError.noData))
    }
}

// MARK: - Send

private extension UnstakingModel {
    private func stakingAction() throws -> StakingAction {
        switch balanceInfo.balanceGroupType {
        case .warmup, .unbonding, .unknown:
            throw UnstakingModelError.notSupported(
                "UnstakingModel doesn't support balanceType: \(balanceInfo.balanceGroupType)"
            )
        case .active:
            return StakingAction(
                amount: balanceInfo.blocked,
                validator: balanceInfo.validatorAddress,
                type: .unstake
            )
        case .withdraw:
            guard case .withdraw(let passthrough) = balanceInfo.actions.first else {
                throw UnstakingModelError.passthroughNotFound
            }

            return StakingAction(
                amount: balanceInfo.blocked,
                validator: balanceInfo.validatorAddress,
                type: .pending(.withdraw(passthrough: passthrough))
            )
        }
    }

    private func send() async throws -> SendTransactionDispatcherResult {
        let action = try stakingAction()
        let transactionInfo = try await stakingManager.transaction(action: action)
        let transaction = stakingMapper.mapToStakeKitTransaction(transactionInfo: transactionInfo, value: action.amount)

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

extension UnstakingModel: SendFeeLoader {
    func updateFees() {}
}

// MARK: - SendAmountInput

extension UnstakingModel: SendAmountInput {
    var amount: SendAmount? {
        let fiat = amountTokenItem.currencyId.flatMap {
            BalanceConverter().convertToFiat(balanceInfo.blocked, currencyId: $0)
        }

        return .init(type: .typical(crypto: balanceInfo.blocked, fiat: fiat))
    }

    var amountPublisher: AnyPublisher<SendAmount?, Never> {
        Just(amount).eraseToAnyPublisher()
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
        mapToSendFee(_state.value)
    }

    var selectedFeePublisher: AnyPublisher<SendFee, Never> {
        _state
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
        amountPublisher.compactMap { $0?.crypto }.eraseToAnyPublisher()
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
    var isReadyToSendPublisher: AnyPublisher<Bool, Never> {
        _state.map { $0?.value?.fee != nil }.eraseToAnyPublisher()
    }

    var summaryTransactionDataPublisher: AnyPublisher<SendSummaryTransactionData?, Never> {
        // Do not show any text in the unstaking flow
        .just(output: nil)
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
        _isLoading.eraseToAnyPublisher()
    }

    func sendTransaction() async throws -> SendTransactionDispatcherResult {
        _isLoading.send(true)
        defer { _isLoading.send(false) }

        return try await send()
    }
}

// MARK: - StakingNotificationManagerInput

extension UnstakingModel: StakingNotificationManagerInput {
    var stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never> {
        stakingManager.statePublisher
    }
}

extension UnstakingModel {
    enum State: Hashable {
        case unstaking(fee: Decimal)
        case withdraw(fee: Decimal)

        var fee: Decimal {
            switch self {
            case .unstaking(let fee): fee
            case .withdraw(let fee): fee
            }
        }
    }
}

enum UnstakingModelError: Error {
    case passthroughNotFound
    case notSupported(String)
}
