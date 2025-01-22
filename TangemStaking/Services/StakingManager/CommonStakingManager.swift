//
//  CommonStakingManager.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 28.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import TangemFoundation

class CommonStakingManager {
    private let integrationId: String
    private let wallet: StakingWallet
    private let provider: StakingAPIProvider
    private let logger: Logger
    private let analyticsLogger: StakingAnalyticsLogger

    private(set) var balances: [StakingBalance]?

    // MARK: Private

    private let _state = CurrentValueSubject<StakingManagerState, Never>(.loading)
    private var canStakeMore: Bool {
        switch wallet.item.network {
        case .solana, .cosmos, .tron, .ethereum, .binance: true
        default: false
        }
    }

    init(
        integrationId: String,
        wallet: StakingWallet,
        provider: StakingAPIProvider,
        logger: Logger,
        analyticsLogger: StakingAnalyticsLogger
    ) {
        self.integrationId = integrationId
        self.wallet = wallet
        self.provider = provider
        self.logger = logger
        self.analyticsLogger = analyticsLogger
    }
}

// MARK: - StakingManager

extension CommonStakingManager: StakingManager {
    var state: StakingManagerState {
        _state.value
    }

    var statePublisher: AnyPublisher<StakingManagerState, Never> {
        _state.eraseToAnyPublisher()
    }

    var allowanceAddress: String? {
        switch (wallet.item.network, wallet.item.contractAddress) {
        case (.ethereum, StakingConstants.polygonContractAddress):
            return "0x5e3ef299fddf15eaa0432e6e66473ace8c13d908"
        default:
            return nil
        }
    }

    func updateState(loadActions: Bool) async {
        updateState(.loading)
        do {
            async let balances = provider.balances(wallet: wallet)
            async let yield = provider.yield(integrationId: integrationId)
            async let actions = loadActions ? provider.actions(wallet: wallet) : []
            try await updateState(state(balances: balances, yield: yield, actions: actions))
        } catch {
            analyticsLogger.logError(
                error,
                currencySymbol: wallet.item.symbol
            )
            logger.error(error)
            updateState(.loadingError(error.localizedDescription))
        }
    }

    func estimateFee(action: StakingAction) async throws -> Decimal {
        switch (state, action.type) {
        case (.loading, _):
            try await waitForLoadingCompletion()
            return try await estimateFee(action: action)
        case (.availableToStake, .stake), (.staked, .stake):
            return try await execute(
                try await provider.estimateStakeFee(
                    request: mapToActionGenericRequest(action: action)
                )
            )
        case (.staked, .unstake):
            return try await execute(
                try await provider.estimateUnstakeFee(
                    request: mapToActionGenericRequest(action: action)
                )
            )
        case (.staked, .pending(let type)):
            return try await getPendingEstimateFee(
                request: mapToActionGenericRequest(action: action),
                type: type
            )
        default:
            log("Invalid staking manager state: \(state), for action: \(action)")
            throw StakingManagerError.stakingManagerStateNotSupportEstimateFeeAction(action: action, state: state)
        }
    }

    func transaction(action: StakingAction) async throws -> StakingTransactionAction {
        switch (state, action.type) {
        case (.loading, _):
            try await waitForLoadingCompletion()
            return try await transaction(action: action)
        case (.availableToStake, .stake), (.staked, .stake):
            return try await getStakeTransactionInfo(
                request: mapToActionGenericRequest(action: action)
            )
        case (.staked, .unstake):
            return try await getUnstakeTransactionInfo(
                request: mapToActionGenericRequest(action: action)
            )
        case (.staked, .pending(let type)):
            return try await getPendingTransactionInfo(
                request: mapToActionGenericRequest(action: action),
                type: type
            )
        default:
            throw StakingManagerError.stakingManagerStateNotSupportTransactionAction(action: action, state: state)
        }
    }

    func transactionDidSent(action: StakingAction) {
        runTask(in: self) {
            await $0.updateState(loadActions: true)
        }
    }
}

// MARK: - Private

private extension CommonStakingManager {
    func updateState(_ state: StakingManagerState) {
        log("Update state to \(state)")
        _state.send(state)
        updateBalances(state)
    }

    func updateBalances(_ state: StakingManagerState) {
        switch state {
        case .loading:
            break
        case .staked(let stakeInfo):
            balances = stakeInfo.balances
        case .availableToStake,
             .loadingError,
             .notEnabled,
             .temporaryUnavailable:
            balances = nil
        }
    }

    func state(balances: [StakingBalanceInfo], yield: YieldInfo, actions: [PendingAction]?) -> StakingManagerState {
        guard yield.isAvailable else {
            return .temporaryUnavailable(yield)
        }

        let stakingBalances = balances.map { balance in
            mapToStakingBalance(balance: balance, yield: yield)
        }

        let mergedBalances = mergeBalancesAndProcessingActions(
            realBalances: stakingBalances,
            processingActions: actions,
            yield: yield
        )

        guard !mergedBalances.isEmpty else {
            return .availableToStake(yield)
        }

        return .staked(.init(balances: mergedBalances, yieldInfo: yield, canStakeMore: canStakeMore))
    }

    private func mergeBalancesAndProcessingActions(
        realBalances: [StakingBalance],
        processingActions: [PendingAction]?,
        yield: YieldInfo
    ) -> [StakingBalance] {
        guard let processingActions, !processingActions.isEmpty else { return realBalances }
        var balances = realBalances

        processingActions.forEach { action in
            switch action.type {
            case .voteLocked, .vote:
                if let lockedBalanceIndex = balanceIndexByType(balances: balances, action: action, type: .locked) {
                    balances.remove(at: lockedBalanceIndex)
                }
                fallthrough
            case .stake:
                balances.append(mapToStakingBalance(action: action, yield: yield, balanceType: .active))
            case .withdraw:
                modifyBalancesByStatus(
                    balances: &balances,
                    action: action,
                    type: .unstaked,
                    reduceBalanceByActionAmount: false,
                    makeInProgress: true
                )
            case .unlockLocked:
                modifyBalancesByStatus(
                    balances: &balances,
                    action: action,
                    type: .locked,
                    reduceBalanceByActionAmount: false,
                    makeInProgress: true
                )
            case .unstake where isFullAmountUnstaking(for: balances, action: action):
                // make existing staking in progress
                modifyBalancesByStatus(
                    balances: &balances,
                    action: action,
                    type: .active,
                    reduceBalanceByActionAmount: false,
                    makeInProgress: true
                )
            case .unstake:
                // for partial unstake reduce amount of existing staking and append new in progress block
                modifyBalancesByStatus(
                    balances: &balances,
                    action: action,
                    type: .active,
                    reduceBalanceByActionAmount: true,
                    makeInProgress: false
                )
                balances.append(mapToStakingBalance(action: action, yield: yield, balanceType: .active))
            default:
                break // do nothing
            }
        }

        return balances
    }

    private func isFullAmountUnstaking(for balances: [StakingBalance], action: PendingAction) -> Bool {
        guard let index = balanceIndexByType(balances: balances, action: action, type: .active) else {
            logger.debug("Couldn't find corresponding staked balance for unstake action")
            return false
        }
        let balance = balances[index]
        return balance.amount == action.amount
    }

    private func balanceIndexByType(
        balances: [StakingBalance],
        action: PendingAction,
        type: StakingBalanceType
    ) -> Int? {
        balances.firstIndex(where: {
            !$0.inProgress
                && $0.balanceType == type
                && $0.validatorType.validator?.address == action.validatorAddress
                && $0.accountAddress.flatMap { action.accountAddresses?.contains($0) } ?? true
        })
    }

    private func modifyBalancesByStatus(
        balances: inout [StakingBalance],
        action: PendingAction,
        type: StakingBalanceType,
        reduceBalanceByActionAmount: Bool,
        makeInProgress inProgress: Bool
    ) {
        guard let index = balanceIndexByType(balances: balances, action: action, type: type) else { return }

        let balance = balances[index]

        let amount = reduceBalanceByActionAmount ? balance.amount - action.amount : balance.amount

        let updatedBalance = StakingBalance(
            item: balance.item,
            amount: amount,
            accountAddress: balance.accountAddress,
            balanceType: balance.balanceType,
            validatorType: balance.validatorType,
            inProgress: inProgress,
            actions: balance.actions
        )

        balances[index] = updatedBalance
    }

    func getStakeTransactionInfo(request: ActionGenericRequest) async throws -> StakingTransactionAction {
        let action = try await execute(try await provider.enterAction(request: request))

        // We have to wait that stakek.it prepared the transaction
        // Otherwise we may get the 404 error
        try await Task.sleep(nanoseconds: Constants.delay)

        let transactions = try await action.transactions.asyncMap { transaction in
            try await execute(try await provider.patchTransaction(id: transaction.id))
        }

        return mapToStakingTransactionAction(
            actionID: action.id,
            amount: action.amount,
            validator: request.validator,
            transactions: transactions
        )
    }

    func getUnstakeTransactionInfo(request: ActionGenericRequest) async throws -> StakingTransactionAction {
        let action = try await execute(try await provider.exitAction(request: request))

        // We have to wait that stakek.it prepared the transaction
        // Otherwise we may get the 404 error
        try await Task.sleep(nanoseconds: Constants.delay)

        let transactions = try await action.transactions.asyncMap { transaction in
            try await execute(try await provider.patchTransaction(id: transaction.id))
        }

        return mapToStakingTransactionAction(
            actionID: action.id,
            amount: action.amount,
            validator: request.validator,
            transactions: transactions
        )
    }

    func getPendingTransactionInfo(request: ActionGenericRequest, type: StakingAction.PendingActionType) async throws -> StakingTransactionAction {
        switch type {
        case .claimRewards(let passthrough),
             .restakeRewards(let passthrough),
             .voteLocked(let passthrough),
             .unlockLocked(let passthrough),
             .restake(let passthrough):
            let request = PendingActionRequest(request: request, passthrough: passthrough, type: type)
            let action = try await getPendingTransactionAction(request: request)
            return action
        case .withdraw(let passthroughs), .claimUnstaked(let passthroughs):
            let actions = try await withThrowingTaskGroup(of: StakingTransactionAction.self) { group in
                for passthrough in passthroughs {
                    let request = PendingActionRequest(request: request, passthrough: passthrough, type: type)
                    group.addTask {
                        try await self.getPendingTransactionAction(request: request)
                    }
                }

                var actions = [StakingTransactionAction]()
                for try await action in group {
                    actions.append(action)
                }
                return actions
            }
//            let actions = try await passthroughs.asyncMap { passthrough in
//                let request = PendingActionRequest(request: request, passthrough: passthrough, type: type)
//                let action = try await getPendingTransactionAction(request: request)
//                return action
//            }

            return mapToStakingTransactionAction(
                amount: request.amount,
                validator: request.validator,
                transactions: actions.flatMap { $0.transactions }
            )
        }
    }

    func getPendingTransactionAction(request: PendingActionRequest) async throws -> StakingTransactionAction {
        let action = try await execute(try await provider.pendingAction(request: request))

        // We have to wait that stakek.it prepared the transaction
        // Otherwise we may get the 404 error
        try await Task.sleep(nanoseconds: Constants.delay)

        let transactions = try await action.transactions.asyncMap { transaction in
            try await execute(try await provider.patchTransaction(id: transaction.id))
        }

        return mapToStakingTransactionAction(
            actionID: action.id,
            amount: action.amount,
            validator: request.request.validator,
            transactions: transactions
        )
    }

    func getPendingEstimateFee(request: ActionGenericRequest, type: StakingAction.PendingActionType) async throws -> Decimal {
        switch type {
        case .claimRewards(let passthrough),
             .restakeRewards(let passthrough),
             .voteLocked(let passthrough),
             .unlockLocked(let passthrough),
             .restake(let passthrough):
            let request = PendingActionRequest(request: request, passthrough: passthrough, type: type)
            return try await execute(try await provider.estimatePendingFee(request: request))
        case .withdraw(let passthroughs), .claimUnstaked(let passthroughs):
            let fees = try await passthroughs.asyncMap { passthrough in
                let request = PendingActionRequest(request: request, passthrough: passthrough, type: type)
                return try await execute(try await provider.estimatePendingFee(request: request))
            }

            return fees.reduce(0, +)
        }
    }

    private func execute<T>(_ request: @autoclosure () async throws -> T) async throws -> T {
        do {
            return try await request()
        } catch {
            analyticsLogger.logError(
                error,
                currencySymbol: wallet.item.symbol
            )
            throw error
        }
    }

    private func waitForLoadingCompletion() async throws {
        // Drop the current `loading` state
        _ = try await _state.dropFirst().first().async()
        // Check if after the loading state we have same status
        // To exclude endless recursion
        if case .loading = state {
            throw StakingManagerError.stakingManagerIsLoading
        }
    }
}

// MARK: - Helping

private extension CommonStakingManager {
    func mapToActionGenericRequest(action: StakingAction) -> ActionGenericRequest {
        .init(
            amount: action.amount,
            address: wallet.address,
            additionalAddresses: getAdditionalAddresses(),
            token: wallet.item,
            validator: action.validatorInfo?.address,
            integrationId: integrationId,
            tronResource: getTronResource()
        )
    }

    func mapToStakingBalance(balance: StakingBalanceInfo, yield: YieldInfo) -> StakingBalance {
        let validatorType: StakingValidatorType = {
            guard let validatorAddress = balance.validatorAddress else {
                return .empty
            }

            let validator = yield.validators.first(where: { $0.address == validatorAddress })
            return validator.map { .validator($0) } ?? .disabled
        }()

        return StakingBalance(
            item: balance.item,
            amount: balance.amount,
            accountAddress: balance.accountAddress,
            balanceType: balance.balanceType,
            validatorType: validatorType,
            inProgress: false,
            actions: balance.actions
        )
    }

    func mapToStakingBalance(
        action: PendingAction,
        yield: YieldInfo,
        balanceType: StakingBalanceType
    ) -> StakingBalance {
        let validatorType: StakingValidatorType = {
            guard let address = action.validatorAddress,
                  let validator = yield.validators.first(where: { $0.address == address }) else {
                return .empty
            }

            return .validator(validator)
        }()

        return StakingBalance(
            item: yield.item,
            amount: action.amount,
            balanceType: balanceType,
            validatorType: validatorType,
            inProgress: true,
            actions: []
        )
    }

    // MARK: - Staking transaction action

    func mapToStakingTransactionAction(
        actionID: String? = nil,
        amount: Decimal,
        validator: String?,
        transactions: [StakingTransactionInfo]
    ) -> StakingTransactionAction {
        StakingTransactionAction(
            id: actionID,
            amount: amount,
            validator: validator,
            transactions: transactions
        )
    }
}

// MARK: - Blockchain specific

private extension CommonStakingManager {
    func getAdditionalAddresses() -> AdditionalAddresses? {
        switch wallet.item.network {
        case .cosmos, .kava, .near:
            guard let compressedPublicKey = try? Secp256k1Key(with: wallet.publicKey).compress() else {
                return nil
            }

            return AdditionalAddresses(cosmosPubKey: compressedPublicKey.base64EncodedString())
        default:
            return nil
        }
    }

    func getTronResource() -> String? {
        switch wallet.item.network {
        case .tron:
            return StakeKitDTO.Actions.ActionArgs.TronResource.energy.rawValue
        default:
            return nil
        }
    }
}

// MARK: - Log

private extension CommonStakingManager {
    func log(_ args: Any) {
        logger.debug("[Staking] \(self) \(wallet.item) \(args)")
    }
}

private extension CommonStakingManager {
    enum Constants {
        static let delay: UInt64 = 1 * NSEC_PER_SEC
    }
}

public enum StakingManagerError: LocalizedError {
    case stakingManagerStateNotSupportTransactionAction(action: StakingAction, state: StakingManagerState)
    case stakingManagerStateNotSupportEstimateFeeAction(action: StakingAction, state: StakingManagerState)
    case stakingManagerIsLoading

    public var errorDescription: String? {
        switch self {
        case .stakingManagerStateNotSupportTransactionAction(let action, let state):
            "StakingManagerNotSupportTransactionAction \(action.type) state \(state.description)"
        case .stakingManagerStateNotSupportEstimateFeeAction(let action, let state):
            "StakingManagerNotSupportTransactionAction \(action.type) state \(state.description)"
        case .stakingManagerIsLoading:
            "StakingManagerIsLoading"
        }
    }
}
