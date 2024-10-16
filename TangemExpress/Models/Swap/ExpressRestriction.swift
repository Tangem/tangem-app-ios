//
//  ExpressRestriction.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 10.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import struct BlockchainSdk.Fee

public enum ExpressRestriction {
    case tooSmallAmount(_ minAmount: Decimal)
    case tooBigAmount(_ maxAmount: Decimal)
    case approveTransactionInProgress(spender: String)
    case insufficientBalance(_ requiredAmount: Decimal)
    case feeCurrencyHasZeroBalance
    case feeCurrencyInsufficientBalanceForTxValue(_ estimatedTxValue: Decimal)
}
