//
//  TONTransactionInput.swift
//  BlockchainSdk
//
//  Created by Alexander Skibin on 03.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct TONTransactionInput {
    let amount: Amount
    let destination: String
    let expireAt: UInt32
    let jettonWalletAddress: String?
    let params: TONTransactionParams?
}
