//
//  BlockchairNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 14.02.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import TangemSdk
import SwiftyJSON
import BitcoinCore

class BlockchairNetworkProvider: BitcoinNetworkProvider {
    var supportsTransactionPush: Bool {
        switch endpoint {
        case .bitcoin:
            return true
        default:
            return false
        }
    }
    
    private let provider: NetworkProvider<BlockchairTarget>
    private let endpoint: BlockchairEndpoint
    private let apiKey: String?
    
    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let dateFormatter = DateFormatter(withFormat: "YYYY-MM-dd HH:mm:ss", locale: "en_US")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return decoder
    }()
    
    var host: String {
        let baseUrl = "https://api.blockchair.com/"
        let endpoint = endpoint.path
        let suffix = apiKey?.sha256() ?? "nil"
        return "\(baseUrl)_\(endpoint)_\(suffix)"
    }
    
    init(endpoint: BlockchairEndpoint, apiKey: String?, configuration: NetworkProviderConfiguration) {
        self.endpoint = endpoint
        self.apiKey = apiKey
        provider = NetworkProvider<BlockchairTarget>(configuration: configuration)
    }
    
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        publisher(for: .address(address: address, limit: 1000, endpoint: endpoint, transactionDetails: true))
            .tryMap { [weak self] json -> (BitcoinResponse, [BlockchairTransactionShort]) in //TODO: refactor to normal JSON
                guard let self = self else { throw WalletError.empty }
                
                let addr = self.mapAddressBlock(address, json: json)
                let address = addr["address"]
                let balance = address["balance"].stringValue
                let script = address["script_hex"].stringValue
                
                guard let decimalSatoshiBalance = Decimal(string: balance) else {
                    throw WalletError.failedToParseNetworkResponse()
                }
                
                guard let transactionsData = try? addr["transactions"].rawData(),
                      let transactions: [BlockchairTransactionShort] = try? self.jsonDecoder.decode([BlockchairTransactionShort].self, from: transactionsData) else {
                    throw WalletError.failedToParseNetworkResponse()
                }
                
                guard let utxoData = try? addr["utxo"].rawData(),
                      let utxos: [BlockchairUtxo] = try? self.jsonDecoder.decode([BlockchairUtxo].self, from: utxoData) else {
                    throw WalletError.failedToParseNetworkResponse()
                }
                
                // Unspents with blockId lower than or equal 1 is not currently available
                // This unspents related to transaction in Mempool and are pending. We should ignore this unspents
                let utxs: [BitcoinUnspentOutput] = utxos.compactMap { utxo -> BitcoinUnspentOutput?  in
                    guard let hash = utxo.transactionHash,
                          let n = utxo.index,
                          let val = utxo.value,
                          let blockId = utxo.blockId,
                          blockId > 1
                    else {
                        return nil
                    }
                    
                    let btx = BitcoinUnspentOutput(transactionHash: hash, outputIndex: n, amount: val, outputScript: script)
                    return btx
                }
                
                let pendingTxs = transactions.filter { $0.blockId <= 1 }
                let hasUnconfirmed = pendingTxs.count != 0
                
                let decimalBtcBalance = decimalSatoshiBalance / self.endpoint.blockchain.decimalValue
                let bitcoinResponse = BitcoinResponse(balance: decimalBtcBalance, hasUnconfirmed: hasUnconfirmed, pendingTxRefs: [], unspentOutputs: utxs)
                
                return (bitcoinResponse, pendingTxs)
            }
            .flatMap { [weak self] (resp: (BitcoinResponse, [BlockchairTransactionShort])) -> AnyPublisher<BitcoinResponse, Error> in
                guard let self = self else { return .emptyFail }
                
                guard !resp.1.isEmpty else {
                    return .justWithError(output: resp.0)
                }
                
                let hashes = resp.1.map { $0.hash }
                return self.publisher(for: .txsDetails(hashes: hashes, endpoint: self.endpoint))
                    .tryMap { [weak self] json -> BitcoinResponse in
                        guard let self = self else { throw WalletError.empty }
                        
                        let data = json["data"]
                        let txsData = hashes.map {
                            data[$0]
                        }
                        
                        let txs = txsData.map {
                            self.getTransactionDetails(from: $0)
                        }
                        
                        let oldResp = resp.0
                        var utxos = oldResp.unspentOutputs
                        
                        let pendingBtcTxs: [PendingTransaction] = txs.compactMap {
                            guard let tx = $0 else { return nil }
                            
                            let pendingTx = tx.toPendingTx(userAddress: address, decimalValue: self.endpoint.blockchain.decimalValue)
                            
                            // We must find unspent outputs if we encounter outgoing transaction,
                            // because Blockchair won't return this unspents in address request as utxos
                            if !pendingTx.isIncoming {
                                let unspents = tx.findUnspentOuputs(for: address)
                                unspents.forEach { utxos.appendIfNotContain($0) }
                            }
                            
                            return pendingTx
                        }
                        
                        //                        let basicTxs = pendingBtcTxs.map { $0.toBasicTx(userAddress: address) }
                        
                        return BitcoinResponse(balance: Decimal(utxos.reduce(0, { $0 + $1.amount })) / self.endpoint.blockchain.decimalValue,
                                               hasUnconfirmed: oldResp.hasUnconfirmed,
                                               pendingTxRefs: pendingBtcTxs,
                                               unspentOutputs: utxos)
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func getFee() -> AnyPublisher<BitcoinFee, Error> {
        publisher(for: .fee(endpoint: endpoint))
            .tryMap { json throws -> BitcoinFee in
                let data = json["data"]
                guard let feePerByteSatoshi = data["suggested_transaction_fee_per_byte_sat"].int  else {
                    throw WalletError.failedToGetFee
                }
                
                let normal = Decimal(feePerByteSatoshi)
                let min = (Decimal(0.8) * normal).rounded(roundingMode: .down)
                let max = (Decimal(1.2) * normal).rounded(roundingMode: .down)
                
                let fee = BitcoinFee(minimalSatoshiPerByte: min,
                                     normalSatoshiPerByte: normal,
                                     prioritySatoshiPerByte: max)
                return fee
            }
            .eraseToAnyPublisher()
    }
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        publisher(for: .send(txHex: transaction, endpoint: endpoint))
            .tryMap { json throws -> String in
                let data = json["data"]
                
                guard let hash = data["transaction_hash"].string else {
                    throw WalletError.failedToParseNetworkResponse()
                }
                
                return hash
            }
            .eraseToAnyPublisher()
    }
    
    func push(transaction: String) -> AnyPublisher<String, Error> {
        send(transaction: transaction)
    }
    
    func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
        publisher(for: .address(address: address, limit: 1000, endpoint: endpoint, transactionDetails: false))
            .tryMap {[weak self] json -> Int in
                guard let self = self else {  throw WalletError.empty }
                
                let addr = self.mapAddressBlock(address, json: json)
                let address = addr["address"]
                
                guard
                    let outputCount = address["output_count"].int,
                    let unspentOutputCount = address["unspent_output_count"].int
                else { return 0 }
                
                return outputCount - unspentOutputCount
            }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    func getTransactionInfo(hash: String, address: String) -> AnyPublisher<PendingTransaction, Error> {
        publisher(for: .txDetails(txHash: hash, endpoint: endpoint))
            .tryMap { [weak self] json -> PendingTransaction in
                guard let self = self else { throw WalletError.empty }
                
                let txJson = json["data"]["\(hash)"]
                
                guard let tx = self.getTransactionDetails(from: txJson) else {
                    throw WalletError.failedToParseNetworkResponse()
                }
                
                return tx.toPendingTx(userAddress: address, decimalValue: self.endpoint.blockchain.decimalValue)
            }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    private func publisher(for type: BlockchairTarget.BlockchairTargetType) -> AnyPublisher<JSON, MoyaError> {
        provider
            .requestPublisher(BlockchairTarget(type: type, apiKey: apiKey))
            .filterSuccessfulStatusAndRedirectCodes()
            .mapSwiftyJSON()
    }
    
    private func getTransactionDetails(from json: JSON) -> BlockchairTransactionDetailed? {
        guard let txData = try? json.rawData(),
              let tx = try? self.jsonDecoder.decode(BlockchairTransactionDetailed.self, from: txData)
        else { return nil }
        
        return tx
    }
}

extension BlockchairNetworkProvider: BlockchairAddressBlockMapper {}
