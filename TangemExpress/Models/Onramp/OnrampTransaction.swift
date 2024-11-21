//
//  OnrampTransaction.swift
//  TangemApp
//
//  Created by Aleksei Muraveinik on 21.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct OnrampTransaction {
    public let fromAmount: Decimal
    public let toAmount: Decimal?
    public let status: OnrampTransactionStatus
    public let externatTxURL: String?
}
