//
//  ExpressManagerRestriction.swift
//  TangemSwapping
//
//  Created by Sergey Balashov on 10.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum ExpressManagerRestriction {
    case pairNotFound
    case notEnoughAmountForSwapping(_ minAmount: Decimal)
    case permissionRequired(spender: String)
    case notEnoughBalanceForSwapping(_ requiredAmount: Decimal)
}
