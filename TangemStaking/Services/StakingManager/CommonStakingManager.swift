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

class CommonStakingManager {
    private let integrationId: String
    private let wallet: StakingWallet
    private let provider: StakingAPIProvider
    private let logger: Logger

    // MARK: Private

    private let _state = CurrentValueSubject<StakingManagerState, Never>(.loading)

    init(
        integrationId: String,
        wallet: StakingWallet,
        provider: StakingAPIProvider,
        logger: Logger
    ) {
        self.integrationId = integrationId
        self.wallet = wallet
        self.provider = provider
        self.logger = logger
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

    func updateState() async throws {
        updateState(.loading)
        do {
            async let balances = provider.balances(wallet: wallet)
            async let yield = provider.yield(integrationId: integrationId)

            try await updateState(state(balances: balances, yield: yield))
        } catch {
            logger.error(error)
            throw error
        }
    }

    func estimateFee(action: StakingAction) async throws -> Decimal {
        switch (state, action.type) {
        case (.availableToStake, .stake), (.staked, .stake):
            try await provider.estimateStakeFee(
                request: mapToActionGenericRequest(action: action)
            )
        case (.staked, .unstake):
            try await provider.estimateUnstakeFee(
                request: mapToActionGenericRequest(action: action)
            )
        case (.staked, .pending(let type)):
            try await getPendingEstimateFee(
                request: mapToActionGenericRequest(action: action),
                type: type
            )
        default:
            log("Invalid staking manager state: \(state), for action: \(action)")
            throw StakingManagerError.stakingManagerStateNotSupportTransactionAction(action: action)
        }
    }

    func transaction(action: StakingAction) async throws -> StakingTransactionAction {
        switch (state, action.type) {
        case (.availableToStake, .stake), (.staked, .stake):
            try await getStakeTransactionInfo(
                request: mapToActionGenericRequest(action: action)
            )
        case (.staked, .unstake):
            try await getUnstakeTransactionInfo(
                request: mapToActionGenericRequest(action: action)
            )
        case (.staked, .pending(let type)):
            try await getPendingTransactionInfo(
                request: mapToActionGenericRequest(action: action),
                type: type
            )
        default:
            throw StakingManagerError.stakingManagerStateNotSupportTransactionAction(action: action)
        }
    }
}

// MARK: - Private

private extension CommonStakingManager {
    func updateState(_ state: StakingManagerState) {
        log("Update state to \(state)")
        _state.send(state)
    }

    func state(balances: [StakingBalanceInfo], yield: YieldInfo) -> StakingManagerState {
        guard yield.isAvailable else {
            return .temporaryUnavailable(yield)
        }

        guard !balances.isEmpty else {
            return .availableToStake(yield)
        }

        let canStakeMore = canStakeMore(item: yield.item)

        return .staked(.init(balances: balances, yieldInfo: yield, canStakeMore: canStakeMore))
    }

    func getStakeTransactionInfo(request: ActionGenericRequest) async throws -> StakingTransactionAction {
        let action = try await provider.enterAction(request: request)

        // We have to wait that stakek.it prepared the transaction
        // Otherwise we may get the 404 error
        try await Task.sleep(nanoseconds: Constants.delay)

        let transactions = try await action.transactions.asyncMap { transaction in
            try await provider.patchTransaction(id: transaction.id)
        }

        return StakingTransactionAction(id: action.id, amount: action.amount, transactions: transactions)
    }

    func getUnstakeTransactionInfo(request: ActionGenericRequest) async throws -> StakingTransactionAction {
        let action = try await provider.exitAction(request: request)

        // We have to wait that stakek.it prepared the transaction
        // Otherwise we may get the 404 error
        try await Task.sleep(nanoseconds: Constants.delay)

        let transactions = try await action.transactions.asyncMap { transaction in
            try await provider.patchTransaction(id: transaction.id)
        }

        return StakingTransactionAction(id: action.id, amount: action.amount, transactions: transactions)
    }

    func getPendingTransactionInfo(request: ActionGenericRequest, type: StakingAction.PendingActionType) async throws -> StakingTransactionAction {
        switch type {
        case .claimRewards(_, let passthrough),
             .restakeRewards(_, let passthrough),
             .voteLocked(_, let passthrough),
             .unlockLocked(let passthrough):
            let request = PendingActionRequest(request: request, passthrough: passthrough, type: type)
            let action = try await getPendingTransactionAction(request: request)
            return action
        case .withdraw(let validator, let passthroughs):
            if passthroughs.isEmpty {
                throw StakingManagerError.pendingActionNotFound(validator: validator)
            }

            let actions = try await passthroughs.asyncMap { passthrough in
                let request = PendingActionRequest(request: request, passthrough: passthrough, type: type)
                let action = try await getPendingTransactionAction(request: request)
                return action
            }

            return StakingTransactionAction(amount: request.amount, transactions: actions.flatMap { $0.transactions })
        }
    }

    func getPendingTransactionAction(request: PendingActionRequest) async throws -> StakingTransactionAction {
        let action = try await provider.pendingAction(request: request)

        // We have to wait that stakek.it prepared the transaction
        // Otherwise we may get the 404 error
        try await Task.sleep(nanoseconds: Constants.delay)

        let transactions = try await action.transactions.asyncMap { transaction in
            try await provider.patchTransaction(id: transaction.id)
        }

        return StakingTransactionAction(id: action.id, amount: action.amount, transactions: transactions)
    }

    func getPendingEstimateFee(request: ActionGenericRequest, type: StakingAction.PendingActionType) async throws -> Decimal {
        switch type {
        case .claimRewards(_, let passthrough),
             .restakeRewards(_, let passthrough),
             .voteLocked(_, let passthrough),
             .unlockLocked(let passthrough):
            let request = PendingActionRequest(request: request, passthrough: passthrough, type: type)
            return try await provider.estimatePendingFee(request: request)
        case .withdraw(let validator, let passthroughs):
            if passthroughs.isEmpty {
                throw StakingManagerError.pendingActionNotFound(validator: validator)
            }

            let fees = try await passthroughs.asyncMap { passthrough in
                let request = PendingActionRequest(request: request, passthrough: passthrough, type: type)
                return try await provider.estimatePendingFee(request: request)
            }

            return fees.reduce(0, +)
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
            validator: action.validator,
            integrationId: integrationId,
            tronResource: getTronResource()
        )
    }

    func canStakeMore(item: StakingTokenItem) -> Bool {
        switch item.network {
        case .solana, .cosmos, .tron:
            return true
        default:
            return false
        }
    }
}

// MARK: - Blockchain specific

private extension CommonStakingManager {
    func getAdditionalAddresses() -> AdditionalAddresses? {
        switch wallet.item.network {
        case .cosmos:
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
    case stakingManagerStateNotSupportTransactionAction(action: StakingAction)
    case stakedBalanceNotFound(validator: String)
    case pendingActionNotFound(validator: String)
    case transactionNotFound
    case notImplemented
    case notFound

    public var errorDescription: String? {
        switch self {
        case .stakingManagerStateNotSupportTransactionAction(let action):
            "stakingManagerStateNotSupportTransactionAction \(action)"
        case .stakedBalanceNotFound(let validator):
            "stakedBalanceNotFound \(validator)"
        case .pendingActionNotFound(let validator):
            "pendingActionNotFound \(validator)"
        case .transactionNotFound:
            "transactionNotFound"
        case .notImplemented:
            "notImplemented"
        case .notFound:
            "notFound"
        }
    }
}
