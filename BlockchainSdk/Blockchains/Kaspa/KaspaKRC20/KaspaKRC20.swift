//
// KaspaKRC20.swift
// BlockchainSdk
//
// Created by Sergei Iakovlev on 16.10.2024
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct KaspaIncompleteTokenTransactionStorageID: CustomStringConvertible, Hashable, Identifiable {
    let id: String

    init(contract: String) {
        id = "KaspaTokenIncompleteTransactions\(contract)"
    }
}

enum KaspaKRC20 {
    static let RevealTransactionMassConstant: Decimal = 4100

    struct CommitTransction {
        let transaction: KaspaTransaction
        let hashes: [Data]
        let redeemScript: KaspaKRC20.RedeemScript
        let sourceAddress: String
        let params: IncompleteTokenTransactionParams
    }

    struct RevealTransaction {
        let transaction: KaspaTransaction
        let hashes: [Data]
        let redeemScript: KaspaKRC20.RedeemScript
    }

    struct IncompleteTokenTransactionParams: TransactionParams, Codable {
        let transactionId: String
        let amount: UInt64
        let envelope: KaspaKRC20.Envelope

        public init(transactionId: String, amount: UInt64, envelope: KaspaKRC20.Envelope) {
            self.transactionId = transactionId
            self.amount = amount
            self.envelope = envelope
        }
    }

    struct RevealTransactionFeeParameter: FeeParameters {
        let amount: Amount
    }

    struct Envelope: Codable {
        let p: String
        let op: String
        let amt: String
        let to: String
        let tick: String

        init(amount: Decimal, recipient: String, ticker: String) {
            p = "krc-20"
            op = "transfer"
            amt = amount.description
            to = recipient
            tick = ticker
        }

        var data: Data {
            let kasplexId = "kasplex".data(using: .utf8)!
            let kasplexIdCount = UInt8(kasplexId.count & 0xff)

            let payload = "{\"amt\":\"\(amt)\",\"op\":\"\(op)\",\"p\":\"\(p)\",\"tick\":\"\(tick)\",\"to\":\"\(to)\"}".data(using: .utf8)!
            let payloadCount = UInt8(payload.count & 0xff)

            let elements = [
                OpCode.OP_FALSE.value.data,
                OpCode.OP_IF.value.data,
                kasplexIdCount.data,
                kasplexId,
                OpCode.OP_1.value.data,
                OpCode.OP_0.value.data,
                OpCode.OP_0.value.data,
                OpCode.OP_PUSHDATA1.value.data,
                payloadCount.data,
                payload,
                OpCode.OP_ENDIF.value.data,
            ]

            return elements.reduce(Data(), +)
        }
    }

    struct RedeemScript {
        let publicKey: Data
        let envelope: KaspaKRC20.Envelope

        init(publicKey: Data, envelope: KaspaKRC20.Envelope) {
            self.publicKey = publicKey
            self.envelope = envelope
        }

        var data: Data {
            return UInt8(publicKey.count & 0xff).data + publicKey + OpCode.OP_CODESEPARATOR.value.data + envelope.data
        }

        var redeemScriptHash: Data {
            return OpCode.OP_HASH256.value.data + UInt8(32).data + data.hashBlake2b(outputLength: 32)! + OpCode.OP_EQUAL.value.data
        }
    }
}
