//
//  BlockchainSDKNotificationMapper.swift
//  TangemFoundation
//
//  Created by Sergey Balashov on 21.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import enum BlockchainSdk.ValidationError
import enum BlockchainSdk.WithdrawalNotification
import enum BlockchainSdk.FeeResourceType

struct BlockchainSDKNotificationMapper {
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem

    private var tokenItemSymbol: String { tokenItem.currencySymbol }
    private var isFeeCurrency: Bool { tokenItem == feeTokenItem }

    init(tokenItem: TokenItem, feeTokenItem: TokenItem) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
    }

    func mapToValidationErrorEvent(_ validationError: ValidationError) -> ValidationErrorEvent {
        switch validationError {
        case .balanceNotFound, .invalidAmount, .invalidFee:
            return .invalidNumber
        case .amountExceedsBalance, .totalExceedsBalance:
            return .insufficientBalance
        case .feeExceedsBalance where isFeeCurrency:
            // If the fee more than the fee/coin balance and we try to send feeCurrency e.g. coin
            // We have to show just `insufficientBalance` without `openFeeCurrency` button
            return .insufficientBalance
        case .feeExceedsBalance:
            return .insufficientBalanceForFee(
                configuration: .init(
                    transactionAmountTypeName: tokenItem.name,
                    feeAmountTypeName: feeTokenItem.name,
                    feeAmountTypeCurrencySymbol: feeTokenItem.currencySymbol,
                    feeAmountTypeIconName: feeTokenItem.blockchain.iconNameFilled,
                    networkName: tokenItem.networkName,
                    currencyButtonTitle: nil
                )
            )
        case .dustAmount(let minimumAmount), .dustChange(let minimumAmount):
            let amountText = "\(minimumAmount.value) \(tokenItemSymbol)"
            return .dustRestriction(minimumAmountFormatted: amountText, minimumChangeFormatted: amountText)
        case .minimumBalance(let minimumBalance):
            return .existentialDeposit(amount: minimumBalance.value, amountFormatted: minimumBalance.string())
        case .maximumUTXO(let blockchainName, let newAmount, let maxUtxo):
            return .amountExceedMaximumUTXO(amount: newAmount.value, amountFormatted: newAmount.string(), blockchainName: blockchainName, maxUTXO: maxUtxo)
        case .reserve(let amount):
            return .insufficientAmountToReserveAtDestination(minimumAmountFormatted: amount.string())
        case .cardanoHasTokens:
            return .cardanoCannotBeSentBecauseHasTokens
        case .cardanoInsufficientBalanceToSendToken:
            return .cardanoInsufficientBalanceToSendToken(tokenSymbol: tokenItemSymbol)
        case .insufficientFeeResource(.mana, let current, let max):
            return .notEnoughMana(current: current, max: max)
        case .amountExceedsFeeResourceCapacity(.mana, let availableAmount):
            return .manaLimit(availableAmount: availableAmount)
        case .feeExceedsMaxFeeResource:
            return .koinosInsufficientBalanceToSendKoin
        case .minimumRestrictAmount(let restrictAmount):
            return .minimumRestrictAmount(restrictAmountFormatted: restrictAmount.string())
        case .remainingAmountIsLessThanRentExtemption(let amount):
            return .remainingAmountIsLessThanRentExtemption(amount: amount.description)
        }
    }

    func mapToWithdrawalNotificationEvent(_ notification: WithdrawalNotification) -> WithdrawalNotificationEvent {
        switch notification {
        case .feeIsTooHigh(let reduceAmountBy):
            return .reduceAmountBecauseFeeIsTooHigh(
                amount: reduceAmountBy.value,
                amountFormatted: reduceAmountBy.string(),
                blockchainName: tokenItem.blockchain.displayName
            )
        case .cardanoWillBeSendAlongToken(let amount):
            return .cardanoWillBeSendAlongToken(
                cardanoAmountFormatted: amount.value.description,
                tokenSymbol: tokenItem.currencySymbol
            )
        }
    }
}
