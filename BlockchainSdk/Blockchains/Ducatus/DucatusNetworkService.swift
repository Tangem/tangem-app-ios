//
//  DucatusNetworkService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 17.02.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Moya

class DucatusNetworkService: BitcoinNetworkProvider {
    private let provider: BitcoreProvider
    
    var host: String { provider.host }
    var supportsTransactionPush: Bool { false }
    
    init(configuration: NetworkProviderConfiguration) {
        provider = BitcoreProvider(configuration: configuration)
    }

    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        return Publishers.Zip(provider.getBalance(address: address), provider.getUnspents(address: address))
            .tryMap { balance, unspents throws -> BitcoinResponse in
                guard let confirmed = balance.confirmed,
                    let unconfirmed = balance.unconfirmed else {
                        throw WalletError.failedToParseNetworkResponse()
                }
                
                let utxs: [BitcoinUnspentOutput] = unspents.compactMap { utxo -> BitcoinUnspentOutput?  in
                    guard let hash = utxo.mintTxid,
                        let n = utxo.mintIndex,
                        let val = utxo.value,
                        let script = utxo.script else {
                            return nil
                    }
                    
                    let btx = BitcoinUnspentOutput(transactionHash: hash, outputIndex: n, amount: UInt64(val), outputScript: script)
                    return btx
                }
                
                let balance = Decimal(confirmed)/Blockchain.ducatus.decimalValue
                return BitcoinResponse(balance: balance, hasUnconfirmed: unconfirmed != 0, pendingTxRefs: [], unspentOutputs: utxs)
        }
        .eraseToAnyPublisher()
    }
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        return provider.send(transaction)
            .tryMap { response throws -> String in
                if let id = response.txid {
                    return id
                } else {
                    throw WalletError.failedToParseNetworkResponse()
                }
        }.eraseToAnyPublisher()
    }
    
    func push(transaction: String) -> AnyPublisher<String, Error> {
        .anyFail(error: "Rbf not supported")
    }
    
    func getFee() -> AnyPublisher<BitcoinFee, Error> {
        let fee = BitcoinFee(minimalSatoshiPerByte: 89,
                             normalSatoshiPerByte: 144,
                             prioritySatoshiPerByte: 350)
        
        return Just(fee)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
	
	func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
		Fail(error: BlockchainSdkError.notImplemented)
			.eraseToAnyPublisher()
	}
}
