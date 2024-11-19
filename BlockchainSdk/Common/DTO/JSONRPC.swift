//
//  JSONRPC.Request.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 05.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum JSONRPC {
    struct Request<Parameter>: Encodable where Parameter: Encodable {
        let jsonrpc: Version?
        let id: Int
        let method: String
        let params: Parameter?

        init(jsonrpc: Version? = .v2, id: Int, method: String, params: Parameter?) {
            self.jsonrpc = jsonrpc
            self.id = id
            self.method = method
            self.params = params
        }
    }

    struct Response<Output, Failure> where Output: Decodable, Failure: Decodable, Failure: Swift.Error {
        let jsonrpc: String
        let id: Int
        let result: Swift.Result<Output, Failure>
    }

    struct APIError: Codable, LocalizedError {
        let code: Int?
        let message: String?

        var errorDescription: String? {
            let values = [code.map { "code: \($0)" }, message.map { "message: \($0)" }]
            return values.compactMap { $0 }.joined(separator: ", ")
        }
    }

    enum Version: String, Encodable {
        case v2 = "2.0"
    }
}

// MARK: - Request + Encoding

extension JSONRPC.Request {
    func string(encoder: JSONEncoder = .init()) throws -> String {
        let messageData = try encoder.encode(self)

        guard let string = String(bytes: messageData, encoding: .utf8) else {
            throw NSError(domain: "Invalid request", code: -1, userInfo: nil)
        }

        return string
    }
}

// MARK: - Result + Decoding

extension JSONRPC.Response: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let result: Result<Output, Failure>

        if let success = try container.decodeIfPresent(Output.self, forKey: .result) {
            result = .success(success)
        } else if let failure = try container.decodeIfPresent(Failure.self, forKey: .error) {
            result = .failure(failure)
        } else {
            let context = DecodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Neither \"result\" nor \"error\" keys present in the JSON payload"
            )
            throw DecodingError.valueNotFound(type(of: result), context)
        }

        self.init(
            jsonrpc: try container.decode(forKey: .jsonrpc),
            id: try container.decode(forKey: .id),
            result: result
        )
    }

    enum CodingKeys: CodingKey {
        case jsonrpc
        case id
        case result
        case error
    }
}
