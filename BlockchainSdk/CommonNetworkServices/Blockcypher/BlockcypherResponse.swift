//
//  BlockcypherResponse.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 07.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import BitcoinCore

/// Response for standart address request
struct BlockcypherAddressResponse : Codable {
    let address: String?
    let balance: Decimal?
    let unconfirmedBalance: Decimal?
    let txrefs: [BlockcypherTxref]?
    let unconfirmedTxrefs: [BlockcypherTxref]?
    
    private enum CodingKeys: String, CodingKey {
        case address, balance, txrefs
        case unconfirmedBalance = "unconfirmed_balance", unconfirmedTxrefs = "unconfirmed_txrefs"
    }
}

/// Response for full address request. This response contain full information about transaction that Blockcypher can provide
struct BlockcypherFullAddressResponse<EndpointTx: Codable & BlockcypherPendingTxConvertible>: Codable {
    let address: String?
    let balance: Decimal?
    let unconfirmedBalance: Decimal?
    let nTx: Int?
    let unconfirmedNTx: Int?
    let txs: [EndpointTx]?
    
    private enum CodingKeys: String, CodingKey {
        case address, balance, txs
        case unconfirmedBalance = "unconfirmed_balance", nTx = "n_tx", unconfirmedNTx = "unconfirmed_n_tx"
    }
}

// Transaction for standart address request
struct BlockcypherTxref: Codable {
    let hash: String?
    let outputIndex: Int?
    let value: Int64?
    let confirmations: Int64?
    let outputScript: String?
    let spent: Bool?
    let received: String?
    
    private enum CodingKeys: String, CodingKey {
        case hash = "tx_hash", outputIndex = "tx_output_n", outputScript = "script"
        case value, confirmations, spent, received
    }
}

extension BlockcypherTxref {
    func toUnspentOutput() -> BitcoinUnspentOutput? {
        guard
            let hash = hash,
            let outputIndex = outputIndex,
            let value = value,
            let script = outputScript,
            spent == false
        else { return nil }
        
        return BitcoinUnspentOutput(transactionHash: hash, outputIndex: outputIndex, amount: UInt64(value), outputScript: script)
    }
}

struct BlockcypherFeeResponse: Codable {
    let low_fee_per_kb: Int64?
    let medium_fee_per_kb: Int64?
    let high_fee_per_kb: Int64?
}

/// Protocol for Blockcypher transactions for unified converting to PendingTransaction model
protocol BlockcypherPendingTxConvertible {
    var hash: String { get }
    var fees: Decimal { get }
    var received: Date { get }
    var inputs: [BlockcypherInput] { get }
    var outputs: [BlockcypherOutput] { get }

    func toPendingTx(userAddress: String, decimalValue: Decimal) -> PendingTransaction
}

extension BlockcypherPendingTxConvertible {
    func toPendingTx(userAddress: String, decimalValue: Decimal) -> PendingTransaction {
        var source: String = .unknown
        var destination: String = .unknown
        var value: Decimal?
        var isIncoming: Bool = false

        if let _ = inputs.first(where: { $0.addresses?.contains(userAddress) ?? false } ), let txDestination = outputs.first(where: { !($0.addresses?.contains(userAddress) ?? false) } ) {
            destination = txDestination.addresses?.first ?? .unknown
            source = userAddress
            value = txDestination.value
        } else if let txDestination = outputs.first(where: { $0.addresses?.contains(userAddress) ?? false } ), let txSource = inputs.first(where: { !($0.addresses?.contains(userAddress) ?? false) } ) {
            isIncoming = true
            destination = userAddress
            source = txSource.addresses?.first ?? .unknown
            value = txDestination.value
        }

        return PendingTransaction(hash: hash,
                                  destination: destination,
                                  value: (value ?? 0) / decimalValue,
                                  source: source,
                                  fee: fees / decimalValue,
                                  date: received,
                                  isIncoming: isIncoming,
                                  transactionParams: BitcoinTransactionParams(inputs: inputs.compactMap { $0.toBitcoinInput() } ))
    }
}

struct BlockcypherTransaction: Codable {
    let block: Int?
    let hash: String?
    let received: String?
    let confirmed: String?
    let inputs: [BlockcypherInput]?
    let outputs: [BlockcypherOutput]?
}

struct BlockcypherInput: Codable {
    let transactionHash: String?
    let index: Int?
    let value: UInt64?
    let addresses: [String]?
    let sequence: Int?
    let script: String?
    
    private enum CodingKeys: String, CodingKey {
        case transactionHash = "prev_hash", value = "output_value", index = "output_index"
        case addresses, sequence, script
    }
    
    func toBitcoinInput() -> BitcoinInput? {
        guard
            let hash = transactionHash,
            let sequence = sequence,
            let address = addresses?.first,
            let index = index,
            let value = value
        else { return nil }
        
        return .init(sequence: sequence, address: address, outputIndex: index, outputValue: value, prevHash: hash)
    }
    
    func toBtcInput() -> BitcoinTransactionInput? {
        guard
            let hash = transactionHash,
            let index = index,
            let amount = value,
            let script = script,
            let sender = addresses?.first,
            let sequence = sequence
        else { return nil }
        
        let output = BitcoinUnspentOutput(transactionHash: hash, outputIndex: index, amount: amount, outputScript: script)
        return BitcoinTransactionInput(unspentOutput: output,
                                       sender: sender,
                                       sequence: sequence)
    }
}

struct BlockcypherOutput: Codable {
    let value: Decimal? // UInt64 can overflow with large ETH amounts
    let script: String?
    let addresses: [String]?
    let scriptType: String?
    let spentBy: String?
    
    private enum CodingKeys: String, CodingKey {
        case value, script, addresses
        case scriptType = "script_type", spentBy = "spent_by"
    }
    
    func toBtcOutput(decimals: Decimal) -> BitcoinTransactionOutput? {
        guard
            let amount = value,
            let recipient = addresses?.first
        else { return nil }
        
        return BitcoinTransactionOutput(amount: amount / decimals,
                                        recipient: recipient)
    }
}

/// Bitcoin transaction structure for blockcypher response
struct BlockcypherBitcoinTx: Codable, BlockcypherPendingTxConvertible {
    let blockIndex: Int64
    let hash: String
    let addresses: [String]
    let total: Decimal
    let fees: Decimal
    let size: Int64
    let confirmations: Int
    let received: Date
    let doubleSpendTx: String?
    let optInRbf: Bool?
    let inputs: [BlockcypherInput]
    let outputs: [BlockcypherOutput]
    
    private enum CodingKeys: String, CodingKey {
        case hash, addresses, total, fees, size, confirmations, received, inputs, outputs
        case blockIndex = "block_index", doubleSpendTx = "double_spend_tx", optInRbf = "opt_in_rbf"
    }
    
    func findUnspentOutput(for sourceAddress: String) -> BitcoinUnspentOutput? {
        var txOutputIndex: Int = -1
        guard
            outputs.enumerated().contains(where: {
                guard
                    $0.element.addresses?.contains(sourceAddress) ?? false,
                    $0.element.spentBy == nil
                else { return false }
                
                txOutputIndex = $0.offset
                return true
            }),
            txOutputIndex >= 0,
            let script = outputs[txOutputIndex].script,
            let value = outputs[txOutputIndex].value
        else {
            return nil
        }
        
        let btc = BitcoinUnspentOutput(transactionHash: hash, outputIndex: txOutputIndex, amount: (value.rounded() as NSDecimalNumber).uint64Value, outputScript: script)
        return btc
    }
}

/// Ethereum transaction structure for blockcypher response
struct BlockcypherEthereumTransaction: Codable, BlockcypherPendingTxConvertible {
    let blockHeight: Int64
    let hash: String
    let total: Decimal // UInt64 can overflow with large ETH amounts
    let fees: Decimal
    let size: Int
    let gasLimit: UInt64
    let gasUsed: UInt64?
    let gasPrice: UInt64
    let received: Date
    let confirmations: Int
    let inputs: [BlockcypherInput]
    let outputs: [BlockcypherOutput]
    
    private enum CodingKeys: String, CodingKey {
        case blockHeight = "block_height", gasLimit = "gas_limit", gasUsed = "gas_used", gasPrice = "gas_price"
        case hash, total, fees, size, received, confirmations, inputs, outputs
    }
}


struct BlockcypherSendResponse: Decodable {
    let tx: BlockcypherBitcoinSendTx
}

extension BlockcypherSendResponse {
    struct BlockcypherBitcoinSendTx: Decodable {
        let hash: String
    }
}
