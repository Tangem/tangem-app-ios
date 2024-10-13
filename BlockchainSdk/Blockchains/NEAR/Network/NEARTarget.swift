//
//  NEARTarget.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 13.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct NEARTarget {
    private static var encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    let baseURL: URL
    let target: Target
}

// MARK: - Auxiliary types

extension NEARTarget {
    enum Target {
        // Returns most recent protocol configuration.
        case protocolConfig
        /// Returns gas price for the most recent block.
        case gasPrice
        /// Returns basic account information.
        case viewAccount(accountId: String)
        /// Returns basic information for a particular public key.
        /// - publicKey: has the following format "ed25519:%public_key% (where %public_key% is a Base58 encoded string)".
        case viewAccessKey(accountId: String, publicKey: String)
        /// Sends a transaction and immediately returns transaction hash.
        /// - transaction: a Base64 encoded string.
        case sendTransactionAsync(transaction: String)
        /// Sends a transaction and waits until transaction is fully complete. (Has a 10 second timeout)
        /// - transaction: a Base64 encoded string.
        case sendTransactionAwait(transaction: String)
        /// Queries status of a transaction by hash and returns the final transaction result.
        case transactionStatus(accountId: String, transactionHash: String)
    }
}

// MARK: - TargetType protocol conformance

extension NEARTarget: TargetType {
    var path: String {
        return ""
    }

    var method: Moya.Method {
        .post
    }

    var task: Moya.Task {
        switch target {
        case .gasPrice:
            return .requestJSONRPC(
                id: Constants.jsonRPCMethodId,
                method: "gas_price",
                params: [NullValue()]
            )
        case .protocolConfig:
            return .requestJSONRPC(
                id: Constants.jsonRPCMethodId,
                method: "EXPERIMENTAL_protocol_config",
                params: NEARNetworkParams.ProtocolConfig(finality: .final)
            )
        case .viewAccount(let accountId):
            return .requestJSONRPC(
                id: Constants.jsonRPCMethodId,
                method: "query",
                params: NEARNetworkParams.ViewAccount(
                    requestType: .viewAccount,
                    finality: .final,
                    accountId: accountId
                ),
                encoder: Self.encoder
            )
        case .viewAccessKey(let accountId, let publicKey):
            return .requestJSONRPC(
                id: Constants.jsonRPCMethodId,
                method: "query",
                params: NEARNetworkParams.ViewAccessKey(
                    requestType: .viewAccessKey,
                    finality: .final,
                    accountId: accountId,
                    publicKey: publicKey
                ),
                encoder: Self.encoder
            )
        case .sendTransactionAsync(let transaction):
            return .requestJSONRPC(
                id: Constants.jsonRPCMethodId,
                method: "broadcast_tx_async",
                params: NEARNetworkParams.Transaction(payload: transaction)
            )
        case .sendTransactionAwait(let transaction):
            return .requestJSONRPC(
                id: Constants.jsonRPCMethodId,
                method: "broadcast_tx_commit",
                params: NEARNetworkParams.Transaction(payload: transaction)
            )
        case .transactionStatus(let accountId, let transactionHash):
            return .requestJSONRPC(
                id: Constants.jsonRPCMethodId,
                method: "tx",
                params: [
                    transactionHash,
                    accountId,
                ]
            )
        }
    }

    var headers: [String: String]? {
        return [
            "Content-Type": "application/json",
            "Accept": "application/json",
        ]
    }
}

// MARK: - Constants

private extension NEARTarget {
    enum Constants {
        static let jsonRPCMethodId: Int = 1
    }
}
