//
//  NodeRequest.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 08.02.2024.
//

import Foundation

struct NodeRequest<T: Encodable>: Encodable {
    let jsonrpc = "2.0"
    let id: String
    let method: String
    let params: [T]
}

extension NodeRequest {
    static func sendRequest(signedTransaction: T) -> Self {
        NodeRequest(id: "send transaction", method: "sendrawtransaction", params: [signedTransaction])
    }

    static func estimateFeeRequest(method: String = "estimatesmartfee", confirmationBlocks: T? = nil) -> Self {
        NodeRequest(id: "estimate fee", method: method, params: confirmationBlocks.flatMap { [$0] } ?? [])
    }
}
