//
//  BitcoinModels.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 17/06/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

struct BitcoinFee {
    let minimalSatoshiPerByte: Decimal
    let normalSatoshiPerByte: Decimal
    let prioritySatoshiPerByte: Decimal
}

/// Unified bitcoin response that contain all information for blockchain sdk. Maps information from API's responses
struct BitcoinResponse {
    let balance: Decimal
    let hasUnconfirmed: Bool
    let pendingTxRefs: [PendingTransaction]
    let unspentOutputs: [BitcoinUnspentOutput]

    init(balance: Decimal, hasUnconfirmed: Bool, pendingTxRefs: [PendingTransaction], unspentOutputs: [BitcoinUnspentOutput]) {
        self.balance = balance
        self.hasUnconfirmed = hasUnconfirmed
        self.pendingTxRefs = pendingTxRefs
        self.unspentOutputs = unspentOutputs
    }
}

/// Full bitcoin transaction. Currently using only in loading single transaction. In future can be used for displaying transaction detalization
struct BitcoinTransaction {
    let hash: String
    let isConfirmed: Bool
    let time: Date
    let inputs: [BitcoinTransactionInput]
    let outputs: [BitcoinTransactionOutput]
}

struct BitcoinTransactionInput {
    let unspentOutput: BitcoinUnspentOutput
    let sender: String
    let sequence: Int
}

struct BitcoinTransactionOutput {
    let amount: Decimal
    let recipient: String
}

struct BitcoinUnspentOutput {
    let transactionHash: String
    let outputIndex: Int
    let amount: UInt64
    let outputScript: String
}

extension Array where Element == BitcoinUnspentOutput {
    mutating func appendIfNotContain(_ utxo: BitcoinUnspentOutput) {
        if !contains(where: { $0.transactionHash == utxo.transactionHash }) {
            append(utxo)
        }
    }
}
