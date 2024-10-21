//
//  RavencoinWalletManager.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 14.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

/// These are the current default values in the ravencore library involved on these checks:
/// Transaction.FEE_PER_KB: 10000 (satoshis per kilobyte) = 0.0001 RVN per Kilobyte
/// Transaction.DUST_AMOUNT: 642 (satoshis)
/// Source: https://github.com/raven-community/ravencore-lib/blob/master/docs/transaction.md

class RavencoinWalletManager: BitcoinWalletManager {
    override var dustValue: Amount {
        let value = 642 / wallet.blockchain.decimalValue
        return Amount(with: wallet.blockchain, value: value)
    }
}
