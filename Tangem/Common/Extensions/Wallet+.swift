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
    func hasFeeCurrency(amountType: Amount.AmountType) -> Bool {
        let feeAmountType = feeAmountType(transactionAmountType: amountType)
        let feeAmount = amounts[feeAmountType]?.value ?? 0

        return feeAmount > 0
    }

    private func feeAmountType(transactionAmountType: Amount.AmountType) -> Amount.AmountType {
        switch blockchain.feePaidCurrency {
        case .coin:
            return .coin
        case .token(let value):
            return .token(value: value)
        case .sameCurrency:
            return transactionAmountType
        }
    }
}
