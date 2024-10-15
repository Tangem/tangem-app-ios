//
//  BinanceTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 15.02.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import BinanceChain
import struct TangemSdk.Secp256k1Key

class BinanceTransactionBuilder {
    var binanceWallet: BinanceWallet
    private var message: Message?
    
    init(walletPublicKey: Data, isTestnet: Bool) throws {
        let compressedKey = try Secp256k1Key(with: walletPublicKey).compress()
        binanceWallet = BinanceWallet(publicKey: compressedKey)
        if isTestnet {
            binanceWallet.chainId = "Binance-Chain-Nile"
            binanceWallet.endpoint = BinanceChain.Endpoint.testnet.rawValue
        } else {
            binanceWallet.chainId = "Binance-Chain-Tigris"
            binanceWallet.endpoint = BinanceChain.Endpoint.mainnet.rawValue
        }
    }
    
    func buildForSign(transaction: Transaction) -> Message? {
        let amount = transaction.amount.value
        let targetAddress = transaction.destinationAddress
        guard let symbol = transaction.amount.type == .coin ?  transaction.amount.currencySymbol : transaction.contractAddress else {
            return nil
        }
        
        let memo = (transaction.params as? BinanceTransactionParams)?.memo ?? ""
        message = Message.transfer(symbol: symbol, amount: Double("\(amount)")!, to: targetAddress, memo: memo, wallet: binanceWallet)
        return message!
    }
    
    func buildForSend(signature: Data, hash: Data) -> Message? {
        guard let message = message else {
            return nil
        }
        
        message.add(signature: signature)
        return message
    }
}
