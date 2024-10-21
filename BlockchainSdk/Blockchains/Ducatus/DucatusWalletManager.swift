//
//  DucatusWalletManager.swift
//
//
//  Created by Alexander Osokin on 28.09.2020.
//

import Foundation

class DucatusWalletManager: BitcoinWalletManager {
    override func updateWallet(with response: [BitcoinResponse]) {
        let singleResponse = response.first!
        wallet.add(coinValue: singleResponse.balance)
        txBuilder.unspentOutputs = singleResponse.unspentOutputs
        loadedUnspents = singleResponse.unspentOutputs
        if singleResponse.hasUnconfirmed {
            if wallet.pendingTransactions.isEmpty {
                wallet.addDummyPendingTransaction()
            }
        } else {
            // We believe that a transaction will be confirmed within 30 seconds
            let date = Date(timeIntervalSinceNow: -30)
            wallet.removePendingTransaction(older: date)
        }
    }
}
