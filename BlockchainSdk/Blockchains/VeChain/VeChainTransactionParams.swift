//
//  VeChainTransactionParams.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 20.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct VeChainTransactionParams: TransactionParams {
    let publicKey: Wallet.PublicKey
    let lastBlockInfo: VeChainBlockInfo
    let nonce: UInt
}
