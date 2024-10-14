//
//  NEARTransactionParams.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 20.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct NEARTransactionParams: TransactionParams {
    let publicKey: Wallet.PublicKey
    let currentNonce: UInt
    let recentBlockHash: String
}
