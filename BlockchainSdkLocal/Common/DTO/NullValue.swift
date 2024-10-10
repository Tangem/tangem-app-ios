//
//  NullValue.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 23.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// Encoded/decoded as a `null` value (not to be confused with the "null" string).
struct NullValue {}

// MARK: - Codable protocol conformance

extension NullValue: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        guard container.decodeNil() else {
            let context = DecodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Expected null (not \"null\") value, found meaningful value instead"
            )
            throw DecodingError.valueNotFound(NullValue.self, context)
        }

        self.init()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}
