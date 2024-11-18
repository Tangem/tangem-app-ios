//
//  AssetRequirementsCondition.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 23.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// Represents a particular action that must be performed to fulfill the requirements of a given kind of 'asset'.
/// An 'asset' can be either a coin or token.
public enum AssetRequirementsCondition {
    /// The exact value of the fee for this type of condition is unknown.
    case paidTransaction(blockchain: Blockchain)
    /// The exact value of the fee for this type of condition is stored in `feeAmount`.
    case paidTransactionWithFee(blockchain: Blockchain, feeAmount: Amount)
    @available(*, unavailable, message: "Token trust lines support not implemented yet")
    case minimumBalanceChange(newMinimumBalance: Amount)
}
