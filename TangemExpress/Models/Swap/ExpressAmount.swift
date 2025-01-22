//
//  ExpressAmount.swift
//  TangemApp
//
//  Created by Sergey Balashov on 23.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum ExpressAmount {
    /// Usual transfer for CEX
    case transfer(amount: Decimal)

    /// For `DEX` / `DEX/Bridge` operations
    case dex(txValue: Decimal, txData: Data)
}
