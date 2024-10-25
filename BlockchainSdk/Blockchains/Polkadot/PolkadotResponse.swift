//
//  PolkadotResponse.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 27.01.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import ScaleCodec

struct PolkadotJsonRpcResponse<T: Codable>: Codable {
    let jsonRpc: String
    let id: Int?
    let result: T?
    let error: PolkadotJsonRpcError?

    private enum CodingKeys: String, CodingKey {
        case jsonRpc = "jsonrpc"
        case id, result, error
    }
}

struct PolkadotJsonRpcError: Codable {
    let code: Int?
    let message: String?

    var error: Error {
        NSError(domain: message ?? .unknown, code: code ?? -1, userInfo: nil)
    }
}

struct PolkadotHeader: Codable {
    let number: String
}

struct PolkadotRuntimeVersion: Codable {
    let specName: String
    let specVersion: UInt32
    let transactionVersion: UInt32
}

struct PolkadotQueriedInfo: Codable {
    let partialFee: String
}

struct PolkadotAccountInfo: ScaleDecodable {
    init(from decoder: ScaleDecoder) throws {
        nonce = try decoder.decode()
        consumers = try decoder.decode()
        providers = try decoder.decode()
        sufficients = try decoder.decode()
        data = try decoder.decode()
    }

    var nonce: UInt32
    var consumers: UInt32
    var providers: UInt32
    var sufficients: UInt32
    let data: PolkadotAccountData
}

struct PolkadotAccountData: ScaleDecodable {
    init(from decoder: ScaleDecoder) throws {
        free = try decoder.decode(BigUInt.self, .b256)
    }

    var free: BigUInt
}
