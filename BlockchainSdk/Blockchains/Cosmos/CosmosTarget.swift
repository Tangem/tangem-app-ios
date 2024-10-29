//
//  CosmosTarget.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 10.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct CosmosTarget {
    let baseURL: URL
    let type: CosmosTargetType
}

extension CosmosTarget {
    enum CosmosTargetType {
        case accounts(address: String)
        case balances(address: String)
        case querySmartContract(contractAddress: String, query: Data)
        case simulate(data: Data)
        case txs(data: Data)
        case transactionStatus(hash: String)
    }
}

extension CosmosTarget: TargetType {
    var path: String {
        switch type {
        case .accounts(let address):
            return "cosmos/auth/v1beta1/accounts/\(address)"
        case .balances(let address):
            return "cosmos/bank/v1beta1/balances/\(address)"
        case .querySmartContract(let contractAddress, let query):
            return "cosmwasm/wasm/v1/contract/\(contractAddress)/smart/\(query.base64EncodedString())"
        case .simulate:
            return "cosmos/tx/v1beta1/simulate"
        case .txs:
            return "cosmos/tx/v1beta1/txs"
        case .transactionStatus(let hash):
            return "cosmos/tx/v1beta1/txs/\(hash)"
        }
    }

    var method: Moya.Method {
        switch type {
        case .accounts, .balances, .transactionStatus, .querySmartContract:
            return .get
        case .simulate, .txs:
            return .post
        }
    }

    var task: Moya.Task {
        switch type {
        case .accounts, .balances, .transactionStatus, .querySmartContract:
            return .requestPlain
        case .simulate(let data), .txs(let data):
            return .requestData(data)
        }
    }

    var headers: [String: String]? {
        [
            "Content-Type": "application/json",
        ]
    }
}
