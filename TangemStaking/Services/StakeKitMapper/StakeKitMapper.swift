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

    func mapToEnterRequest(request: ActionGenericRequest) -> StakeKitDTO.EstimateGas.Enter.Request {
        StakeKitDTO.EstimateGas.Enter.Request(
            integrationId: request.integrationId,
            addresses: mapToAddress(request: request),
            args: mapToActionsArgs(request: request)
        )
    }

    func mapToExitRequest(request: ActionGenericRequest) -> StakeKitDTO.EstimateGas.Exit.Request {
        StakeKitDTO.EstimateGas.Exit.Request(
            integrationId: request.integrationId,
            addresses: mapToAddress(request: request),
            args: mapToActionsArgs(request: request)
        )
    }

    func mapToPendingRequest(request: PendingActionRequest) -> StakeKitDTO.EstimateGas.Pending.Request {
        StakeKitDTO.EstimateGas.Pending.Request(
            type: mapToActionType(from: request.type),
            integrationId: request.request.integrationId,
            passthrough: request.passthrough,
            addresses: mapToAddress(request: request.request),
            args: mapToActionsArgs(request: request.request)
        )
    }

    func mapToAddress(request: ActionGenericRequest) -> StakeKitDTO.Address {
        StakeKitDTO.Address(
            address: request.address,
            additionalAddresses: request.additionalAddresses.flatMap {
                StakeKitDTO.Address.AdditionalAddresses(cosmosPubKey: $0.cosmosPubKey)
            }
        )
    }

    func mapToActionsArgs(request: ActionGenericRequest) -> StakeKitDTO.Actions.Args {
        StakeKitDTO.Actions.Args(
            amount: request.amount.description,
            validatorAddress: request.validator,
            validatorAddresses: request.validator.map { [$0] },
            inputToken: mapToTokenDTO(from: request.token),
            tronResource: request.tronResource
        )
    }

    func mapToActionType(from action: StakingAction.PendingActionType) -> StakeKitDTO.Actions.ActionType {
        switch action {
        case .withdraw: .withdraw
        case .claimRewards: .claimRewards
        case .restakeRewards: .restakeRewards
        case .voteLocked: .voteLocked
        case .unlockLocked: .unlockLocked
        case .restake: .restake
        case .claimUnstaked: .claimUnstaked
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
        guard let transactions = response.transactions?.filter({ $0.status != .skipped }),
              !transactions.isEmpty else {
            throw StakeKitMapperError.noData("EnterAction.transactions not found")
        }

        guard let amount = Decimal(string: response.amount) else {
            throw StakeKitMapperError.noData("EnterAction.amount not found")
        }

        let actionTransaction: [ActionTransaction] = transactions.map { transaction in
            ActionTransaction(id: transaction.id, stepIndex: transaction.stepIndex)
        }

        return try EnterAction(
            id: response.id,
            status: mapToActionStatus(from: response.status),
            amount: amount,
            currentStepIndex: response.currentStepIndex,
            transactions: actionTransaction
        )
    }

    func mapToExitAction(from response: StakeKitDTO.Actions.Exit.Response) throws -> ExitAction {
        guard let transactions = response.transactions?.filter({ $0.status != .skipped }),
              !transactions.isEmpty else {
            throw StakeKitMapperError.noData("ExitAction.transactions not found")
        }

        guard let amount = Decimal(string: response.amount) else {
            throw StakeKitMapperError.noData("ExitAction.amount not found")
        }

        let actionTransaction: [ActionTransaction] = transactions.map { transaction in
            ActionTransaction(id: transaction.id, stepIndex: transaction.stepIndex)
        }

        return try ExitAction(
            id: response.id,
            status: mapToActionStatus(from: response.status),
            amount: amount,
            currentStepIndex: response.currentStepIndex,
            transactions: actionTransaction
        )
    }

    func mapToPendingActions(from response: StakeKitDTO.Actions.List.Response) throws -> [PendingAction] {
        try response.data.map { action in
            guard let amountString = action.amount, let amount = Decimal(string: amountString) else {
                throw StakeKitMapperError.noData("PendingAction.amount not found")
            }

            let actionTransaction: [ActionTransaction] = action.transactions.map { transaction in
                ActionTransaction(id: transaction.id, stepIndex: transaction.stepIndex)
            }

            return try PendingAction(
                id: action.id,
                accountAddresses: action.accountAddresses,
                status: mapToActionStatus(from: action.status),
                amount: amount,
                type: mapToActionType(from: action.type),
                currentStepIndex: action.currentStepIndex,
                transactions: actionTransaction,
                validatorAddress: action.validatorAddress ?? action.validatorAddresses?.first
            )
        }
    }

    func mapToPendingAction(from response: StakeKitDTO.Actions.Pending.Response) throws -> PendingAction {
        guard let transactions = response.transactions?.filter({ $0.status != .skipped }),
              !transactions.isEmpty else {
            throw StakeKitMapperError.noData("PendingAction.transactions not found")
        }

        guard let amount = Decimal(string: response.amount) else {
            throw StakeKitMapperError.noData("PendingAction.amount not found")
        }

        let actionTransaction: [ActionTransaction] = transactions.map { transaction in
            ActionTransaction(id: transaction.id, stepIndex: transaction.stepIndex)
        }

        return try PendingAction(
            id: response.id,
            status: mapToActionStatus(from: response.status),
            amount: amount,
            type: mapToActionType(from: response.type),
            currentStepIndex: response.currentStepIndex,
            transactions: actionTransaction,
            validatorAddress: response.validatorAddress ?? response.validatorAddresses?.first
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
            unsignedTransactionData: mapToTransactionUnsignedData(from: unsignedTransaction, network: response.network),
            fee: fee
        )
    }

    // MARK: - Balance

    func mapToBalanceInfo(from response: [StakeKitDTO.Balances.Response]) throws -> [StakingBalanceInfo] {
        guard let balances = response.first?.balances else {
            return []
        }

        return try balances.compactMap { balance in
            guard let amount = Decimal(stringValue: balance.amount) else {
                return nil
            }

            // For Polygon token we can receive a staking balance with zero amount
            guard amount > 0 else {
                return nil
            }

            return try StakingBalanceInfo(
                item: mapToStakingTokenItem(from: balance.token),
                amount: amount,
                accountAddress: balance.accountAddress,
                balanceType: mapToBalanceType(from: balance),
                validatorAddress: balance.validatorAddress ?? balance.validatorAddresses?.first,
                actions: mapToStakingBalanceInfoPendingAction(from: balance)
            )
        }
    }

    func mapToStakingBalanceInfoPendingAction(
        from balance: StakeKitDTO.Balances.Response.Balance
    ) throws -> [StakingPendingActionInfo] {
        try balance.pendingActions.compactMap { action in
            StakingPendingActionInfo(
                type: try mapToActionType(from: action.type),
                passthrough: action.passthrough
            )
        }
    }

    func mapToActionType(
        from actionType: StakeKitDTO.Actions.ActionType
    ) throws -> StakingPendingActionInfo.ActionType {
        switch actionType {
        case .stake: .stake
        case .vote: .vote
        case .unstake: .unstake
        case .withdraw: .withdraw
        case .claimRewards: .claimRewards
        case .restakeRewards: .restakeRewards
        case .voteLocked, .revote: .voteLocked
        case .unlockLocked: .unlockLocked
        case .restake: .restake
        case .claimUnstaked: .claimUnstaked
        default: throw StakeKitMapperError.noData("PendingAction.type \(actionType) doesn't supported")
        }
    }

    func mapToBalanceType(
        from balance: StakeKitDTO.Balances.Response.Balance
    ) throws -> StakingBalanceType {
        switch balance.type {
        case .available:
            throw StakeKitMapperError.notImplement
        case .locked:
            return .locked
        case .preparing:
            return .warmup
        case .staked:
            return .active
        case .unstaking, .unlocking:
            return .unbonding(date: balance.date)
        case .unstaked:
            return .unstaked
        case .rewards:
            return .rewards
        }
    }

    // MARK: - Yield

    func mapToYieldInfo(from response: StakeKitDTO.Yield.Info.Response) throws -> YieldInfo {
        guard let enterAction = response.args.enter,
              let exitAction = response.args.exit else {
            throw StakeKitMapperError.noData("Enter or exit action is not found")
        }

        let validators = response.validators.map(mapToValidatorInfo)
        let preferredValidators = validators.filter { $0.preferred }.sorted { lhs, rhs in
            if lhs.apr == rhs.apr {
                return lhs.partner
            }

            return lhs.apr ?? 0 > rhs.apr ?? 0
        }

        let rewardRateValues = RewardRateValues(
            aprs: preferredValidators.compactMap(\.apr),
            rewardRate: response.rewardRate
        )

        let item = try mapToStakingTokenItem(from: response.token)

        return try YieldInfo(
            id: response.id,
            isAvailable: response.isAvailable,
            rewardType: mapToRewardType(from: response.rewardType),
            rewardRateValues: rewardRateValues,
            enterMinimumRequirement: enterAction.args.amount.minimum ?? .zero,
            exitMinimumRequirement: exitAction.args.amount.minimum ?? .zero,
            validators: validators,
            preferredValidators: preferredValidators,
            item: item,
            unbondingPeriod: mapToPeriod(from: response.metadata.cooldownPeriod),
            warmupPeriod: mapToPeriod(from: response.metadata.warmupPeriod),
            rewardClaimingType: mapToRewardClaimingType(from: response.metadata.rewardClaiming),
            rewardScheduleType: mapToRewardScheduleType(from: response.metadata.rewardSchedule, item: item)
        )
    }

    // MARK: - Validators

    func mapToValidatorInfo(from validator: StakeKitDTO.Validator) -> ValidatorInfo {
        ValidatorInfo(
            address: validator.address,
            name: validator.name ?? "No name",
            preferred: validator.preferred ?? false,
            partner: validator.name?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == StakingConstants.partnerName,
            iconURL: validator.image.flatMap { URL(string: $0) },
            apr: validator.apr
        )
    }

    // MARK: - Inner types

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
        case .canceled:
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

    func mapToRewardScheduleType(
        from type: StakeKitDTO.Yield.Info.Response.Metadata.RewardScheduleType,
        item: StakingTokenItem
    ) throws -> RewardScheduleType {
        switch item.network {
        case .solana: .days(min: 2, max: 3)
        case .cosmos: .seconds(min: 5, max: 12)
        case .tron: .daily
        case .binance: .daily
        case .ethereum where item.contractAddress == StakingConstants.polygonContractAddress: .daily
        default: .generic(type.rawValue)
        }
    }
}

public enum StakeKitMapperError: Error {
    case notImplement
    case noData(String)
    case tronTransactionMappingFailed
}

extension StakeKitMapperError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notImplement: "Not implemented"
        case .noData(let string): string
        case .tronTransactionMappingFailed: "TronTransactionMappingFailed"
        }
    }
}
