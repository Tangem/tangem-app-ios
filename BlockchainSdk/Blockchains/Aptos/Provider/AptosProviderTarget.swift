//
//  AptosProviderTarget.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 26.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

/*
 https://aptos.dev/nodes/aptos-api-spec
 */

struct AptosProviderTarget: TargetType {
    // MARK: - Properties
    
    private let node: NodeInfo
    private let targetType: TargetType
    
    // MARK: - Init
    
    init(node: NodeInfo, targetType: TargetType) {
        self.node = node
        self.targetType = targetType
    }
    
    var baseURL: URL {
        node.url
    }
    
    var isAccountsResourcesRequest: Bool {
        if case .accountsResources = targetType {
            return true
        } else {
            return false
        }
    }

    var path: String {
        switch targetType {
        case .accounts(let address):
            return "v1/accounts/\(address)"
        case .accountsResources(let address):
            return "v1/accounts/\(address)/resources"
        case .estimateGasPrice:
            return "v1/estimate_gas_price"
        case .simulateTransaction:
            return "v1/transactions/simulate"
        case .submitTransaction:
            return "v1/transactions"
        }
    }
    
    var method: Moya.Method {
        switch targetType {
        case .accounts, .accountsResources, .estimateGasPrice:
            return .get
        case .simulateTransaction, .submitTransaction:
            return .post
        }
    }
    
    var task: Moya.Task {
        switch targetType {
        case .accounts, .accountsResources, .estimateGasPrice:
            return .requestPlain
        case .simulateTransaction(let data):
            return .requestCompositeData(
                bodyData: data,
                urlParameters: [
                    "estimate_gas_unit_price": "false",
                    "estimate_max_gas_amount": "true",
                    "estimate_prioritized_gas_unit_price": "false"
                ]
            )
        case .submitTransaction(let data):
            return .requestData(data)
        }
    }
    
    var headers: [String : String]? {
        var headers: [String : String] = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
        
        if let headersKeyInfo = node.headers {
            headers[headersKeyInfo.headerName] = headersKeyInfo.headerValue
        }
        
        return headers
    }
}

extension AptosProviderTarget {
    enum TargetType {
        /*
         Return the authentication key and the sequence number for an account address. Optionally, a ledger version can be specified. If the ledger version is not specified in the request, the latest ledger version is used.
         */
        case accounts(address: String)
        
        /*
         Retrieves all account resources for a given account and a specific ledger version. If the ledger version is not specified in the request, the latest ledger version is used.

         The Aptos nodes prune account state history, via a configurable time window. If the requested ledger version has been pruned, the server responds with a 410.
         */
        case accountsResources(address: String)
        
        /*
         Gives an estimate of the gas unit price required to get a transaction on chain in a reasonable amount of time. The gas unit price is the amount that each transaction commits to pay for each unit of gas consumed in executing the transaction. The estimate is based on recent history: it gives the minimum gas that would have been required to get into recent blocks, for blocks that were full. (When blocks are not full, the estimate will match the minimum gas unit price.)

         The estimation is given in three values: de-prioritized (low), regular, and prioritized (aggressive). Using a more aggressive value increases the likelihood that the transaction will make it into the next block; more aggressive values are computed with a larger history and higher percentile statistics. More details are in AIP-34.
         */
        case estimateGasPrice
        
        /*
         The output of the transaction will have the exact transaction outputs and events that running an actual signed transaction would have. However, it will not have the associated state hashes, as they are not updated in storage. This can be used to estimate the maximum gas units for a submitted transaction.

         To use this, you must:

         - Create a SignedTransaction with a zero-padded signature.
         - Submit a SubmitTransactionRequest containing a UserTransactionRequest containing that signature.
         
         To use this endpoint with BCS, you must submit a SignedTransaction encoded as BCS. See SignedTransaction in types/src/transaction/mod.rs.
         */
        case simulateTransaction(data: Data)
        
        /*
         This endpoint accepts transaction submissions in two formats.

         To submit a transaction as JSON, you must submit a SubmitTransactionRequest. To build this request, do the following:

         Encode the transaction as BCS. If you are using a language that has
         native BCS support, make sure of that library. If not, you may take advantage of /transactions/encode_submission. When using this endpoint, make sure you trust the node you're talking to, as it is possible they could manipulate your request. 2. Sign the encoded transaction and use it to create a TransactionSignature. 3. Submit the request. Make sure to use the "application/json" Content-Type.

         To submit a transaction as BCS, you must submit a SignedTransaction encoded as BCS. See SignedTransaction in types/src/transaction/mod.rs. Make sure to use the application/x.aptos.signed_transaction+bcs Content-Type.
         */
        case submitTransaction(data: Data)
    }
}
