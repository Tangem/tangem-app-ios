//
//  SubscanAPIResult.Error.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 21.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// Returned on 2xx/4xx/5xx HTTP status codes.
extension SubscanAPIResult {
    struct Error: Swift.Error {
        let code: Int
        let message: String?
    }
}

// MARK: - Decodable protocol conformance

extension SubscanAPIResult.Error: Decodable {
    private enum CodingKeys: CodingKey {
        case code
        case message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let code = try container.decode(Int.self, forKey: CodingKeys.code)

        // Normal API responses always have a `code` field with 0 value
        guard code != 0 else {
            throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "Not an error"))
        }

        self.code = code
        self.message = try? container.decodeIfPresent(String.self, forKey: CodingKeys.message)
    }
}
