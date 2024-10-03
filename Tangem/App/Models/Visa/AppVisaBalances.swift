//
//  AppVisaBalances.swift
//  Tangem
//
//  Created by Andrew Son on 22/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemVisa

struct AppVisaBalances {
    let totalBalance: Decimal?
    let verifiedBalance: Decimal?
    let available: Decimal?
    let blocked: Decimal?
    let debt: Decimal?
    let pendingRefund: Decimal?

    init(balances: VisaBalances) {
        totalBalance = balances.totalBalance
        verifiedBalance = balances.verifiedBalance
        available = balances.available
        blocked = balances.blocked
        debt = balances.debt
        pendingRefund = balances.pendingRefund
    }

    init(
        totalBalance: Decimal?,
        verifiedBalance: Decimal?,
        available: Decimal?,
        blocked: Decimal?,
        debt: Decimal?,
        pendingRefund: Decimal?
    ) {
        self.totalBalance = totalBalance
        self.verifiedBalance = verifiedBalance
        self.available = available
        self.blocked = blocked
        self.debt = debt
        self.pendingRefund = pendingRefund
    }
}
