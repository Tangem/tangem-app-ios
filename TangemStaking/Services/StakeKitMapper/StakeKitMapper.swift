//
//  StakeKitMapper.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 27.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct StakeKitMapper {
    // MARK: - To DTO

    func mapToActionType(from action: PendingActionType) -> StakeKitDTO.Actions.ActionType {
        switch action {
        case .withdraw: .withdraw
        }
    }

    func mapToTokenDTO(from tokenItem: StakingTokenItem) -> StakeKitDTO.Token {
        StakeKitDTO.Token(
            network: tokenItem.network.rawValue,
            name: tokenItem.name,
            decimals: tokenItem.decimals,
            address: tokenItem.contractAddress,
            symbol: tokenItem.symbol
        )
    }

    // MARK: - Actions

    func mapToEnterAction(from response: StakeKitDTO.Actions.Enter.Response) throws -> EnterAction {
        guard let transactions = response.transactions, !transactions.isEmpty else {
            throw StakeKitMapperError.noData("EnterAction.transactions not found")
        }

        let actionTransaction: [ActionTransaction] = try transactions.map { transaction in
            try ActionTransaction(
                id: transaction.id,
                stepIndex: transaction.stepIndex,
                type: mapToTransactionType(from: transaction.type),
                status: mapToTransactionStatus(from: transaction.status)
            )
        }

        return try EnterAction(
            id: response.id,
            status: mapToActionStatus(from: response.status),
            currentStepIndex: response.currentStepIndex,
            transactions: actionTransaction
        )
    }

    func mapToExitAction(from response: StakeKitDTO.Actions.Exit.Response) throws -> ExitAction {
        guard let transactions = response.transactions, !transactions.isEmpty else {
            throw StakeKitMapperError.noData("EnterAction.transactions not found")
        }

        let actionTransaction: [ActionTransaction] = try transactions.map { transaction in
            try ActionTransaction(
                id: transaction.id,
                stepIndex: transaction.stepIndex,
                type: mapToTransactionType(from: transaction.type),
                status: mapToTransactionStatus(from: transaction.status)
            )
        }

        return try ExitAction(
            id: response.id,
            status: mapToActionStatus(from: response.status),
            currentStepIndex: response.currentStepIndex,
            transactions: actionTransaction
        )
    }

    func mapToPendingAction(from response: StakeKitDTO.Actions.Pending.Response) throws -> PendingAction {
        guard let transactions = response.transactions, !transactions.isEmpty else {
            throw StakeKitMapperError.noData("EnterAction.transactions not found")
        }

        let actionTransaction: [ActionTransaction] = try transactions.map { transaction in
            try ActionTransaction(
                id: transaction.id,
                stepIndex: transaction.stepIndex,
                type: mapToTransactionType(from: transaction.type),
                status: mapToTransactionStatus(from: transaction.status)
            )
        }

        return try PendingAction(
            id: response.id,
            status: mapToActionStatus(from: response.status),
            currentStepIndex: response.currentStepIndex,
            transactions: actionTransaction
        )
    }

    // MARK: - Transaction

    func mapToTransactionInfo(from response: StakeKitDTO.Transaction.Response) throws -> StakingTransactionInfo {
        guard let unsignedTransaction = response.unsignedTransaction else {
            throw StakeKitMapperError.noData("Transaction.unsignedTransaction not found")
        }

        guard let fee = response.gasEstimate.flatMap({ Decimal(stringValue: $0.amount) }) else {
            throw StakeKitMapperError.noData("Transaction.gasEstimate not found")
        }

        guard let stakeId = response.stakeId else {
            throw StakeKitMapperError.noData("Transaction.stakeId not found")
        }

        return try StakingTransactionInfo(
            id: response.id,
            actionId: stakeId,
            network: response.network.rawValue,
            type: mapToTransactionType(from: response.type),
            status: mapToTransactionStatus(from: response.status),
            unsignedTransactionData: try mapToTransactionUnsignedData(from: unsignedTransaction, network: response.network),
            fee: fee
        )
    }

    // MARK: - Balance

    func mapToBalanceInfo(from response: [StakeKitDTO.Balances.Response]) throws -> [StakingBalanceInfo] {
        guard let balances = response.first?.balances else {
            throw StakeKitMapperError.noData("Balances not found")
        }

        return try balances.compactMap { balance in
            guard let blocked = Decimal(stringValue: balance.amount) else {
                return nil
            }

            // For Polygon token we can receive a staking balance with zero amount
            guard blocked > 0 else {
                return nil
            }

            return try StakingBalanceInfo(
                item: mapToStakingTokenItem(from: balance.token),
                blocked: blocked,
                // TODO: https://tangem.atlassian.net/browse/IOS-7398
                rewards: .zero,
                balanceGroupType: mapToBalanceGroupType(from: balance.type),
                validatorAddress: balance.validatorAddress,
                actions: mapToStakingBalanceInfoPendingAction(from: balance)
            )
        }
    }

    func mapToStakingBalanceInfoPendingAction(from balance: StakeKitDTO.Balances.Response.Balance) -> [PendingActionType] {
        balance.pendingActions.compactMap { action in
            switch action.type {
            case .withdraw:
                return .withdraw(passthrough: action.passthrough)
            case .claimRewards:
                // TODO: https://tangem.atlassian.net/browse/IOS-7398
                return nil
            default:
                return nil
            }
        }
    }

    // MARK: - Yield

    func mapToYieldInfo(from response: StakeKitDTO.Yield.Info.Response) throws -> YieldInfo {
        guard let enterAction = response.args.enter,
              let exitAction = response.args.exit else {
            throw StakeKitMapperError.noData("Enter or exit action is not found")
        }

        return try YieldInfo(
            id: response.id,
            isAvailable: response.isAvailable,
            apy: response.apy,
            rewardType: mapToRewardType(from: response.rewardType),
            rewardRate: response.rewardRate,
            enterMinimumRequirement: enterAction.args.amount.minimum,
            exitMinimumRequirement: exitAction.args.amount.minimum,
            validators: response.validators.compactMap(mapToValidatorInfo),
            defaultValidator: response.metadata.defaultValidator,
            item: mapToStakingTokenItem(from: response.token),
            unbondingPeriod: mapToPeriod(from: response.metadata.cooldownPeriod),
            warmupPeriod: mapToPeriod(from: response.metadata.warmupPeriod),
            rewardClaimingType: mapToRewardClaimingType(from: response.metadata.rewardClaiming),
            rewardScheduleType: mapToRewardScheduleType(from: response.metadata.rewardSchedule)
        )
    }

    // MARK: - Validators

    func mapToValidatorInfo(from validator: StakeKitDTO.Validator) -> ValidatorInfo? {
        guard validator.preferred == true else {
            return nil
        }

        return ValidatorInfo(
            address: validator.address,
            name: validator.name ?? "No name",
            iconURL: validator.image.flatMap { URL(string: $0) },
            apr: validator.apr
        )
    }

    // MARK: - Inner types

    func mapToTransactionType(from type: StakeKitDTO.Transaction.Response.TransactionType) throws -> TransactionType {
        switch type {
        case .approval: .approval
        case .stake: .stake
        case .unstake: .unstake
        case .withdraw: .withdraw
        case .enter, .exit, .claim, .claimRewards, .reinvest, .send, .unknown:
            throw StakeKitMapperError.notImplement
        }
    }

    func mapToTransactionStatus(from status: StakeKitDTO.Transaction.Response.Status) throws -> TransactionStatus {
        switch status {
        case .created: .created
        case .waitingForSignature: .waitingForSignature
        case .broadcasted: .broadcasted
        case .pending: .pending
        case .confirmed: .confirmed
        case .failed: .failed
        case .notFound, .blocked, .signed, .skipped, .unknown:
            throw StakeKitMapperError.notImplement
        }
    }

    func mapToTransactionUnsignedData(from unsignedData: String, network: StakeKitNetworkType) throws -> String {
        switch network {
        case .tron:
            guard let data = unsignedData.data(using: .utf8) else {
                throw StakeKitMapperError.tronTransactionMappingFailed
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            let tronTransaction = try decoder.decode(StakeKitDTO.Transaction.TronTransaction.self, from: data)
            return tronTransaction.rawDataHex
        default:
            return unsignedData
        }
    }

    func mapToActionStatus(from status: StakeKitDTO.Actions.ActionStatus) throws -> ActionStatus {
        switch status {
        case .created: .created
        case .waitingForNext: .waitingForNext
        case .processing: .processing
        case .failed: .failed
        case .success: .success
        case .canceled, .unknown:
            throw StakeKitMapperError.notImplement
        }
    }

    func mapToStakingTokenItem(from token: StakeKitDTO.Token) throws -> StakingTokenItem {
        guard let network = StakeKitNetworkType(rawValue: token.network) else {
            throw StakeKitMapperError.noData("StakeKitNetworkType not found")
        }

        return StakingTokenItem(
            network: network,
            contractAddress: token.address,
            name: token.name,
            decimals: token.decimals,
            symbol: token.symbol
        )
    }

    func mapToRewardType(from rewardType: StakeKitDTO.Yield.Info.Response.RewardType) -> RewardType {
        switch rewardType {
        case .apr: .apr
        case .apy: .apy
        case .variable: .variable
        }
    }

    func mapToPeriod(from period: StakeKitDTO.Yield.Info.Response.Metadata.Period) -> Period {
        .days(period.days)
    }

    func mapToRewardClaimingType(from type: StakeKitDTO.Yield.Info.Response.Metadata.RewardClaiming) -> RewardClaimingType {
        switch type {
        case .auto: .auto
        case .manual: .manual
        }
    }

    func mapToRewardScheduleType(from type: StakeKitDTO.Yield.Info.Response.Metadata.RewardScheduleType) throws -> RewardScheduleType {
        switch type {
        case .hour: .hour
        case .block, .epoch, .era, .day: .day
        case .week: .week
        case .month: .month
        }
    }

    func mapToBalanceGroupType(
        from balanceType: StakeKitDTO.Balances.Response.Balance.BalanceType
    ) -> BalanceGroupType {
        switch balanceType {
        case .preparing:
            return .warmup
        case .available, .locked, .staked:
            return .active
        case .unstaking, .unlocking:
            return .unbonding
        case .unstaked:
            return .withdraw
        case .rewards, .unknown:
            return .unknown
        }
    }
}

enum StakeKitMapperError: Error {
    case notImplement
    case noData(String)
    case tronTransactionMappingFailed
}
