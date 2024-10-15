//
//  SendBaseDataBuilder.swift
//  TangemApp
//
//  Created by Sergey Balashov on 16.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemStaking

protocol SendBaseDataBuilderInput {
    var bsdkAmount: BSDKAmount? { get }
    var bsdkFee: Fee? { get }
    var isFeeIncluded: Bool { get }

    var selectedPolicy: ApprovePolicy? { get }
    var approveViewModelInput: ApproveViewModelInput? { get }

    var stakingAction: StakingAction.ActionType? { get }
    var validator: ValidatorInfo? { get }
}

extension SendBaseDataBuilderInput {
    var selectedPolicy: ApprovePolicy? { nil }
    var approveViewModelInput: ApproveViewModelInput? { nil }

    var stakingAction: StakingAction.ActionType? { nil }
    var validator: ValidatorInfo? { nil }
}

struct SendBaseDataBuilder {
    private let input: SendBaseDataBuilderInput
    private let walletModel: WalletModel
    private let emailDataProvider: EmailDataProvider

    init(
        input: SendBaseDataBuilderInput,
        walletModel: WalletModel,
        emailDataProvider: EmailDataProvider
    ) {
        self.input = input
        self.walletModel = walletModel
        self.emailDataProvider = emailDataProvider
    }

    func makeMailData(stakingRequestError error: Error) throws -> (dataCollector: EmailDataCollector, recipient: String) {
        guard let fee = input.bsdkFee?.amount else {
            throw SendBaseDataBuilderError.notFound("Fee")
        }

        guard let amount = input.bsdkAmount else {
            throw SendBaseDataBuilderError.notFound("Amount")
        }

        let emailDataCollector = SendScreenDataCollector(
            userWalletEmailData: emailDataProvider.emailData,
            walletModel: walletModel,
            fee: fee,
            destination: "Staking",
            amount: amount,
            isFeeIncluded: input.isFeeIncluded,
            lastError: .init(error: error),
            stakingAction: input.stakingAction,
            validator: input.validator
        )

        let recipient = emailDataProvider.emailConfig?.recipient ?? EmailConfig.default.recipient

        return (dataCollector: emailDataCollector, recipient: recipient)
    }

    func makeMailData(transaction: SendTransactionType, error: SendTxError) -> (dataCollector: EmailDataCollector, recipient: String) {
        switch transaction {
        case .transfer(let bSDKTransaction):
            return makeMailData(transaction: bSDKTransaction, error: error)
        case .staking(let stakingTransactionAction):
            return makeMailData(action: stakingTransactionAction, error: error)
        }
    }

    func makeMailData(transaction: BSDKTransaction, error: SendTxError) -> (dataCollector: EmailDataCollector, recipient: String) {
        let emailDataCollector = SendScreenDataCollector(
            userWalletEmailData: emailDataProvider.emailData,
            walletModel: walletModel,
            fee: transaction.fee.amount,
            destination: transaction.destinationAddress,
            amount: transaction.amount,
            isFeeIncluded: input.isFeeIncluded,
            lastError: .init(error: error),
            stakingAction: nil,
            validator: nil
        )

        let recipient = emailDataProvider.emailConfig?.recipient ?? EmailConfig.default.recipient

        return (dataCollector: emailDataCollector, recipient: recipient)
    }

    func makeMailData(action: StakingTransactionAction, error: SendTxError) -> (dataCollector: EmailDataCollector, recipient: String) {
        let feeValue = action.transactions.reduce(0) { $0 + $1.fee }
        let fee = Amount(with: walletModel.feeTokenItem.blockchain, type: walletModel.feeTokenItem.amountType, value: feeValue)
        let amount = Amount(with: walletModel.tokenItem.blockchain, type: walletModel.amountType, value: action.amount)

        let emailDataCollector = SendScreenDataCollector(
            userWalletEmailData: emailDataProvider.emailData,
            walletModel: walletModel,
            fee: fee,
            destination: "Staking",
            amount: amount,
            isFeeIncluded: input.isFeeIncluded,
            lastError: .init(error: error),
            stakingAction: input.stakingAction,
            validator: input.validator
        )

        let recipient = emailDataProvider.emailConfig?.recipient ?? EmailConfig.default.recipient

        return (dataCollector: emailDataCollector, recipient: recipient)
    }

    func makeDataForExpressApproveViewModel() throws -> (settings: ExpressApproveViewModel.Settings, approveViewModelInput: any ApproveViewModelInput) {
        guard let selectedPolicy = input.selectedPolicy else {
            throw SendBaseDataBuilderError.notFound("Selected approve policy")
        }

        guard let input = input.approveViewModelInput else {
            throw SendBaseDataBuilderError.notFound("ApproveViewModelInput")
        }

        let settings = ExpressApproveViewModel.Settings(
            subtitle: Localization.givePermissionStakingSubtitle(walletModel.tokenItem.currencySymbol),
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            selectedPolicy: selectedPolicy
        )

        return (settings, input)
    }
}

enum SendBaseDataBuilderError: LocalizedError {
    case notFound(String)

    var errorDescription: String? {
        switch self {
        case .notFound(let string):
            "\(string) not found"
        }
    }
}
