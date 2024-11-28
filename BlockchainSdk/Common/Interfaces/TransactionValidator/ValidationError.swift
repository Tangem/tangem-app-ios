//
//  ValidationError.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 12.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum ValidationError: Hashable, LocalizedError {
    case balanceNotFound
    case invalidAmount
    case amountExceedsBalance
    case invalidFee
    case feeExceedsBalance
    case totalExceedsBalance

    case dustAmount(minimumAmount: Amount)
    case dustChange(minimumAmount: Amount)
    case minimumBalance(minimumBalance: Amount)
    case maximumUTXO(blockchainName: String, newAmount: Amount, maxUtxo: Int)
    case reserve(amount: Amount)

    case minimumRestrictAmount(amount: Amount)

    case cardanoHasTokens(minimumAmount: Amount)
    case cardanoInsufficientBalanceToSendToken

    case insufficientFeeResource(type: FeeResourceType, current: Decimal, max: Decimal)
    case amountExceedsFeeResourceCapacity(type: FeeResourceType, availableAmount: Decimal)
    case feeExceedsMaxFeeResource
    case remainingAmountIsLessThanRentFee(amount: Amount)

    public var errorDescription: String? {
        switch self {
        case .balanceNotFound, .cardanoInsufficientBalanceToSendToken, .cardanoHasTokens:
            return WalletError.empty.localizedDescription
        case .amountExceedsBalance:
            return Localization.sendValidationAmountExceedsBalance
        case .dustAmount(let minimumAmount):
            return Localization.sendErrorDustAmountFormat(minimumAmount.description)
        case .dustChange(let minimumAmount):
            return Localization.sendErrorDustChangeFormat(minimumAmount.description)
        case .minimumBalance(let minimumBalance):
            return Localization.sendErrorMinimumBalanceFormat(minimumBalance.string(roundingMode: .plain))
        case .feeExceedsBalance, .feeExceedsMaxFeeResource:
            return Localization.sendValidationInvalidFee
        case .invalidAmount, .amountExceedsFeeResourceCapacity:
            return Localization.sendValidationInvalidAmount
        case .invalidFee:
            return Localization.sendErrorInvalidFeeValue
        case .totalExceedsBalance:
            return Localization.sendValidationInvalidTotal
        case .maximumUTXO(let blockchainName, let newAmount, let maxUtxo):
            return Localization.commonUtxoValidateWithdrawalMessageWarning(
                blockchainName, maxUtxo, newAmount.description
            )
        case .reserve(let amount):
            return Localization.sendErrorNoTargetAccount(amount.description)
        case .insufficientFeeResource(.mana, let current, let max):
            return Localization.koinosInsufficientManaToSendKoinDescription(current, max)
        case .minimumRestrictAmount:
            return Localization.sendValidationInvalidAmount
        case .remainingAmountIsLessThanRentFee(let amount):
            return .none // displayed as notification
        }
    }
}
