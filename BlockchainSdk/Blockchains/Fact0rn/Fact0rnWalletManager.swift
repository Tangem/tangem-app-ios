//
//  Fact0rnWalletManager.swift
//  BlockchainSdk
//
//  Created by Alexander Skibin on 15.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class Fact0rnWalletManager: BitcoinWalletManager {
    override var minimalFee: Decimal { 0.000001 }

    // It needs to be override, as there is no reliable way to reset the pending transactions.
    override func updateWallet(with response: [BitcoinResponse]) {
        let balance = response.reduce(into: 0) { $0 += $1.balance }
        let hasUnconfirmed = response.filter { $0.hasUnconfirmed }.count > 0
        let unspents = response.flatMap { $0.unspentOutputs }

        let coinBalanceValue = balance / wallet.blockchain.decimalValue

        // Reset pending transaction
        if coinBalanceValue != wallet.amounts[.coin]?.value, !hasUnconfirmed {
            wallet.clearPendingTransaction()
        }

        wallet.add(coinValue: balance)
        loadedUnspents = unspents
        txBuilder.unspentOutputs = unspents
    }
}
