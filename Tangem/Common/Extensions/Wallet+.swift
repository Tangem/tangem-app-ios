//
//  Wallet+.swift
//  Tangem
//
//  Created by Alexander Osokin on 25.02.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import SwiftUI

public extension Wallet {
    func feeCurrencyBalance(amountType: Amount.AmountType) -> Decimal {
        let feeAmountType = feeAmountType(transactionAmountType: amountType)
        let feeAmount = amounts[feeAmountType]?.value ?? 0

        return feeAmount
    }

    func hasFeeCurrency(amountType: Amount.AmountType) -> Bool {
        let feeValue = feeCurrencyBalance(amountType: amountType)

        if blockchain.allowsZeroFeePaid {
            return feeValue >= 0
        }

        return feeValue > 0
    }

    private func feeAmountType(transactionAmountType: Amount.AmountType) -> Amount.AmountType {
        switch blockchain.feePaidCurrency {
        case .coin:
            return .coin
        case .token(let value):
            return .token(value: value)
        case .sameCurrency:
            return transactionAmountType
        // Currently, we use this only for Koinos.
        // The MANA (fee resource) amount can only be zero if the KOIN (coin) amount is zero.
        // There is a network restriction that prohibits sending the maximum amount of KOIN,
        // which explicitly means there will always be some KOIN.
        // This also implicitly means there will always be some amount of MANA,
        // because 1 KOIN is able to recharge at a rate of 0.00000231 Mana per second,
        // and this recharge rate scales correspondingly to the amount of KOIN in the balance.
        case .feeResource(let type):
            return .feeResource(type)
        }
    }
}
