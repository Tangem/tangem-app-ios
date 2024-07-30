//
//  StakeKitMapper.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 27.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct StakeKitMapper {
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
            unsignedTransactionData: Data(hexString: unsignedTransaction),
            fee: fee
        )
    }

    // MARK: - Balance

    func mapToBalanceInfo(from response: [StakeKitDTO.Balances.Response]) throws -> StakingBalanceInfo? {
        // There isn't any balances
        guard let balance = response.first?.balances.first else {
            return nil
        }

        guard let blocked = Decimal(stringValue: balance.amount) else {
            throw StakeKitMapperError.noData("Balance.amount not found")
        }

        return StakingBalanceInfo(
            item: mapToStakingTokenItem(from: balance.token),
            blocked: blocked,
            balanceGroupType: mapToBalanceGroupType(from: balance.type)
        )
    }

    // MARK: - Yield

    func mapToYieldInfo(from response: StakeKitDTO.Yield.Info.Response) throws -> YieldInfo {
        guard let enterAction = response.args.enter else {
            throw StakeKitMapperError.noData("EnterAction not found")
        }

        return try YieldInfo(
            id: response.id,
            apy: response.apy,
            rewardType: mapToRewardType(from: response.rewardType),
            rewardRate: response.rewardRate,
            minimumRequirement: enterAction.args.amount.minimum,
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
        case .stake: .stake
        case .enter: .enter
        case .exit: .unstake
        case .claim: .claim
        case .claimRewards: .claimRewards
        case .reinvest, .send, .approve, .unknown:
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

    func mapToStakingTokenItem(from token: StakeKitDTO.Token) -> StakingTokenItem {
        StakingTokenItem(coinId: token.coinGeckoId, contractAdress: token.address)
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
        case .block: .block
        case .hour: .hour
        case .day: .day
        case .week: .week
        case .month: .month
        case .era: .era
        case .epoch: .epoch
        }
    }

    func mapToBalanceGroupType(
        from balanceType: StakeKitDTO.Balances.Response.Balance.BalanceType
    ) -> BalanceGroupType {
        switch balanceType {
        case .preparing, .available, .locked, .staked:
            return .active
        case .unstaking, .unstaked, .unlocking:
            return .unstaked
        case .rewards, .unknown:
            return .unknown
        }
    }
}

enum StakeKitMapperError: Error {
    case notImplement
    case noData(String)
}
