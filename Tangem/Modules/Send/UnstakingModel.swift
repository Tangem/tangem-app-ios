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

struct PendingActionMapper {
    private let balanceInfo: StakingBalanceInfo

    init(balanceInfo: StakingBalanceInfo) {
        self.balanceInfo = balanceInfo
    }

    func getActions() throws -> UnstakingModel.ActionType {
        switch balanceInfo.balanceType {
        case .warmup, .unbonding:
            throw PendingActionMapperError.notSupported(
                "PendingActionMapper doesn't support balanceType: \(balanceInfo.balanceType)"
            )
        case .active:
            return .single(stakingAction(type: .unstake))
        case .withdraw:
            let withdrawIndex = balanceInfo.actions.firstIndex(where: {
                if case .withdraw = $0 {
                    return true
                }
                return false
            })

            guard let withdrawIndex else {
                throw PendingActionMapperError.wrongPendingActionForBalanceType
            }

            return .single(stakingAction(type: .pending(balanceInfo.actions[withdrawIndex])))
        case .rewards:
            let claimRewardsIndex = balanceInfo.actions.firstIndex(where: {
                if case .claimRewards = $0 {
                    return true
                }
                return false
            })

            let restakeRewardsIndex = balanceInfo.actions.firstIndex(where: {
                if case .restakeRewards = $0 {
                    return true
                }
                return false
            })

            guard let claimRewardsIndex, let restakeRewardsIndex else {
                throw PendingActionMapperError.wrongPendingActionForBalanceType
            }

            return .rewards(
                claim: stakingAction(type: .pending(balanceInfo.actions[restakeRewardsIndex])),
                restake: stakingAction(type: .pending(balanceInfo.actions[restakeRewardsIndex]))
            )
        }
    }

    private func stakingAction(type: StakingAction.ActionType) -> StakingAction {
        StakingAction(amount: balanceInfo.amount, validator: balanceInfo.validatorAddress, type: type)
    }
}

enum PendingActionMapperError: Error {
    case passthroughNotFound
    case notSupported(String)
    case wrongPendingActionForBalanceType
}

protocol UnstakingModelStateProvider {
    var state: AnyPublisher<UnstakingModel.State, Never> { get }
}

class UnstakingModel {
    // MARK: - Data

    private let _state = CurrentValueSubject<State?, Never>(.none)
    private let _transactionTime = PassthroughSubject<Date?, Never>()
    private let _isLoading = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Private injections

    private let stakingManager: StakingManager
    private let sendTransactionDispatcher: SendTransactionDispatcher
    private let action: ActionType
    private let amountTokenItem: TokenItem
    private let feeTokenItem: TokenItem
    private let stakingMapper: StakingMapper

    private var estimatedFeeTask: Task<Void, Never>?
    private var bag: Set<AnyCancellable> = []

    init(
        stakingManager: StakingManager,
        sendTransactionDispatcher: SendTransactionDispatcher,
        action: UnstakingModel.ActionType,
        amountTokenItem: TokenItem,
        feeTokenItem: TokenItem
    ) {
        self.stakingManager = stakingManager
        self.sendTransactionDispatcher = sendTransactionDispatcher
        self.action = action
        self.amountTokenItem = amountTokenItem
        self.feeTokenItem = feeTokenItem
        stakingMapper = StakingMapper(
            amountTokenItem: amountTokenItem,
            feeTokenItem: feeTokenItem
        )

        updateState()
    }
}

// MARK: - UnstakingModelStateProvider

extension UnstakingModel: UnstakingModelStateProvider {
    var state: AnyPublisher<State, Never> {
        _state.compactMap { $0 }.eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension UnstakingModel {
    func updateState() {
        estimatedFeeTask?.cancel()

        estimatedFeeTask = runTask(in: self) { model in
            do {
                model.update(fee: .loading)
                let fee = try await model.fee()
                model.update(fee: .loaded(fee))
            } catch {
                AppLog.shared.error(error)
                model.update(fee: .failedToLoad(error: error))
            }
        }
    }

    func update(fee: LoadingValue<Decimal>) {
        _state.send(.init(fee: fee, action: action))
    }

    func fee() async throws -> Decimal {
        return try await stakingManager.estimateFee(action: action.first)
    }

    func mapToSendFee(_ state: State?) -> SendFee {
        switch state {
        case .none:
            return SendFee(option: .market, value: .failedToLoad(error: CommonError.noData))
        case .some(let state):
            let newValue = state.fee.mapValue { value in
                Fee(.init(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: value))
            }

            return SendFee(option: .market, value: newValue)
        }
    }
}

// MARK: - Send

private extension UnstakingModel {
    private func send(action: StakingAction) async throws -> SendTransactionDispatcherResult {
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
            BalanceConverter().convertToFiat(action.first.amount, currencyId: $0)
        }

        return .init(type: .typical(crypto: action.first.amount, fiat: fiat))
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
        _state.map { $0?.fee != nil }.eraseToAnyPublisher()
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

        return try await send(action: action.first)
    }

    func sendAdditionalTransaction() async throws -> SendTransactionDispatcherResult {
        guard case .rewards(_, let restake) = action else {
            throw SendTransactionDispatcherResult.Error.transactionNotFound
        }

        return try await send(action: restake)
    }
}

// MARK: - StakingNotificationManagerInput

extension UnstakingModel: StakingNotificationManagerInput {
    var stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never> {
        stakingManager.statePublisher
    }
}

extension UnstakingModel {
    struct State: Hashable {
        let fee: LoadingValue<Decimal>
        let action: ActionType
    }

    enum ActionType: Hashable {
        case single(StakingAction)
        case rewards(claim: StakingAction, restake: StakingAction)

        var first: StakingAction {
            switch self {
            case .single(let stakingAction): stakingAction
            case .rewards(let claim, _): claim
            }
        }
    }
}

enum UnstakingModelError: Error {
    case actionNotFound
}
