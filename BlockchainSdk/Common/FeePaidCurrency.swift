//
//  FeePaidCurrency.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 15.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// The currency that is used to pay the transaction fees.
public enum FeePaidCurrency {
    /// Fees are paid in the network's main currency.
    case coin
    /// Fees are paid in the specific token of this network.
    case token(value: Token)
    /// Fees are paid in the same currency in which the transaction was made.
    case sameCurrency

    case feeResource(type: FeeResourceType)
}
