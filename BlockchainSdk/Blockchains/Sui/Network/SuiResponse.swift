//
// SuiResponse.swift
// BlockchainSdk
//
// Created by Sergei Iakovlev on 30.08.2024
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Balance

struct SuiGetCoins: Codable {
    struct Coin: Codable, Hashable {
        let coinType: String
        let coinObjectId: String
        let version: String
        let digest: String
        let balance: String
        let previousTransaction: String

        func hash(into hasher: inout Hasher) {
            hasher.combine(digest)
        }
    }

    let hasNextPage: Bool
    let data: [Coin]
    let nextCursor: String?
}

// MARK: - GasPrice

typealias SuiReferenceGasPrice = String

// MARK: - ExecuteTransaction

struct SuiExecuteTransaction: Codable {
    let digest: String
}

// MARK: - DryRunTransaction

struct SuiInspectTransaction: Codable {
    let effects: SuiTransaction.SuiTransactionEffects
    let input: SuiTransaction.SuiTransactionData
}

struct SuiTransaction: Codable {
    // SubTypes
    struct Transaction: Codable {
        struct SuiTransactionInput: Codable {
            let type: String
            //
            let valueType: String?
            let value: String?
            //
            let objectType: String?
            let objectId: String?
            let version: String?
            let digest: String?
        }

        let kind: String
        let inputs: [SuiTransactionInput]
    }

    struct GasData: Codable {
        struct Payment: Codable {
            let objectId: String
            let version: UInt64
            let digest: String
        }

        let owner: String
        let price: String
        let budget: String
        let payment: [Payment]
    }

    struct SuiTransactionData: Codable {
        let messageVersion: String
        let transaction: SuiTransaction.Transaction
        let sender: String
        let gasData: GasData
    }

    struct SuiTransactionGasUsed: Codable {
        let computationCost: String
        let storageCost: String
        let storageRebate: String
        let nonRefundableStorageFee: String
    }

    struct SuiTransactionEffects: Codable {
        struct Status: Codable {
            let status: String
        }

        let messageVersion: String
        let status: Status
        let gasUsed: SuiTransactionGasUsed
        let transactionDigest: String

        func isSuccess() -> Bool {
            status.status == "success"
        }
    }

    // Body
    let data: SuiTransactionData
    let txSignatures: [String]
    let rawTransaction: String
    let effects: SuiTransactionEffects
}
