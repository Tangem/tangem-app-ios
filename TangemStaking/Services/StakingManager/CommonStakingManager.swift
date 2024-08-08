//
//  CommonStakingManager.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 28.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

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
        case (.availableToStake(let yieldInfo), .stake):
            return try await provider.estimateStakeFee(
                amount: action.amount,
                address: wallet.address,
                validator: action.validator,
                integrationId: yieldInfo.id
            )
        case (.staked(_, let yieldInfo), .unstake):
            return try await provider.estimateUnstakeFee(
                amount: action.amount,
                address: wallet.address,
                validator: action.validator,
                integrationId: yieldInfo.id
            )
        case (.staked(let balanceInfo, let yieldInfo), .claimRewards):
            guard let passthrough = balanceInfo.first(where: { $0.passthrough != nil })?.passthrough else {
                fallthrough
            }
            return try await provider.estimateClaimRewardsFee(
                amount: action.amount,
                address: wallet.address,
                validator: action.validator,
                integrationId: yieldInfo.id,
                passthrough: passthrough
            )
        default:
            log("Invalid staking manager state: \(state), for action: \(action)")
            throw StakingManagerError.stakingManagerStateNotSupportTransactionAction(action: action)
        }
    }

    func transaction(action: StakingAction) async throws -> StakingTransactionInfo {
        switch (state, action.type) {
        case (.availableToStake(let yieldInfo), .stake):
            return try await getTransactionToStake(
                amount: action.amount,
                validator: action.validator,
                integrationId: yieldInfo.id
            )
        case (.staked(let balances, let yieldInfo), .unstake):
            guard let balance = balances.first(where: { $0.validatorAddress == action.validator }) else {
                throw StakingManagerError.stakedBalanceNotFound(validator: action.validator)
            }

            return try await getTransactionToUnstake(
                amount: balance.blocked,
                validator: action.validator,
                integrationId: yieldInfo.id
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

    func state(balances: [StakingBalanceInfo]?, yield: YieldInfo) -> StakingManagerState {
        guard let balances else {
            return .availableToStake(yield)
        }

        if balances.contains(where: { $0.balanceGroupType.isActiveOrUnstaked }) {
            return .staked(balances, yield)
        } else {
            return .availableToStake(yield)
        }
    }

    func getTransactionToStake(amount: Decimal, validator: String, integrationId: String) async throws -> StakingTransactionInfo {
        let action = try await provider.enterAction(
            amount: amount,
            address: wallet.address,
            validator: validator,
            integrationId: integrationId
        )

        guard let transactionId = action.transactions.first(where: { $0.stepIndex == action.currentStepIndex })?.id else {
            throw StakingManagerError.transactionNotFound
        }

        // We have to wait that stakek.it prepared the transaction
        // Otherwise we may get the 404 error
        try await Task.sleep(nanoseconds: 1 * NSEC_PER_SEC)
        let transaction = try await provider.patchTransaction(id: transactionId)

        return transaction
    }

    func getTransactionToUnstake(amount: Decimal, validator: String, integrationId: String) async throws -> StakingTransactionInfo {
        let action = try await provider.exitAction(
            amount: amount, address: wallet.address,
            validator: validator,
            integrationId: integrationId
        )

        guard let transactionId = action.transactions.first(where: { $0.stepIndex == action.currentStepIndex })?.id else {
            throw StakingManagerError.transactionNotFound
        }

        // We have to wait that stakek.it prepared the transaction
        // Otherwise we may get the 404 error
        try await Task.sleep(nanoseconds: 1 * NSEC_PER_SEC)
        let transaction = try await provider.patchTransaction(id: transactionId)

        return transaction
    }
}

// MARK: - Log

private extension CommonStakingManager {
    func log(_ args: Any) {
        logger.debug("[Staking] \(self) \(args)")
    }
}

public enum StakingManagerError: Error {
    case stakingManagerStateNotSupportTransactionAction(action: StakingAction)
    case stakedBalanceNotFound(validator: String)
    case transactionNotFound
    case notImplemented
    case notFound
}
