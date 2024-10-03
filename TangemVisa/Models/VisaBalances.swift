//
//  VisaBalances.swift
//  TangemVisa
//
//  Created by Andrew Son on 18/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct VisaBalances {
    public let totalBalance: Decimal?
    public let verifiedBalance: Decimal?
    public let available: Decimal?
    public let blocked: Decimal?
    public let debt: Decimal?
    public let pendingRefund: Decimal?
}
