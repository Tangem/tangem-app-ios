//
//  CosmosModels.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 10.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Account

struct CosmosAccountResponse: Decodable {
    let account: Account
}

extension CosmosAccountResponse {
    struct Account: Decodable {
        let accountNumber: String
        let sequence: String
    }
}

// MARK: - Balance

struct CosmosBalanceResponse: Decodable {
    let balances: [Balance]
}

extension CosmosBalanceResponse {
    struct Balance: Decodable {
        let denom: String
        let amount: String
    }
}

// MARK: - Cosmos WASM smart contract interaction

struct CosmosCW20BalanceRequest: Encodable {
    private let balance: CosmosCW20BalanceAddress

    init(address: String) {
        balance = CosmosCW20BalanceAddress(address: address)
    }
}

private extension CosmosCW20BalanceRequest {
    struct CosmosCW20BalanceAddress: Encodable {
        let address: String
    }
}

struct CosmosCW20QueryResult<D: Decodable>: Decodable {
    let data: D
}

struct CosmosCW20QueryBalanceData: Decodable {
    let balance: String
}

// MARK: - Simulate

struct CosmosSimulateResponse: Decodable {
    let gasInfo: GasInfo
}

extension CosmosSimulateResponse {
    struct GasInfo: Decodable {
        let gasUsed: String
    }
}

// MARK: - TX

struct CosmosTxResponse: Decodable {
    let txResponse: TxResponse
}

extension CosmosTxResponse {
    struct TxResponse: Decodable {
        let height: String
        let txhash: String
        let code: Int
    }
}

// MARK: - Local models

struct CosmosAccountInfo {
    let accountNumber: UInt64?
    let sequenceNumber: UInt64
    let amount: Amount
    let tokenBalances: [Token: Decimal]
    let confirmedTransactionHashes: [String]
}

struct CosmosError: Error, Decodable {
    let code: Int
    let message: String
}
