//
//  NEARNetworkResult.APIError.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 26.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import struct AnyCodable.AnyDecodable

extension NEARNetworkResult {
    struct APIError: Decodable, Error {
        // There are many more types of errors, but we only care about the ones
        // that can be returned from API endpoints in the 'NEARTarget.swift' file.
        enum ErrorTypeName: String, Decodable {
            case handlerError = "HANDLER_ERROR"
            case requestValidationError = "REQUEST_VALIDATION_ERROR"
            case internalError = "INTERNAL_ERROR"
            case unknownError

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                let rawValue = try container.decode(String.self)
                self = ErrorTypeName(rawValue: rawValue) ?? .unknownError
            }
        }

        //  There are many more causes of errors, but we only care about the ones
        // that can be returned from API endpoints in the 'NEARTarget.swift' file.
        enum ErrorCauseName: String, Decodable {
            case unknownBlock = "UNKNOWN_BLOCK"
            case invalidAccount = "INVALID_ACCOUNT"
            case unknownAccount = "UNKNOWN_ACCOUNT"
            case unknownAccessKey = "UNKNOWN_ACCESS_KEY"
            case unavailableShard = "UNAVAILABLE_SHARD"
            case noSyncedBlocks = "NO_SYNCED_BLOCKS"
            case parseError = "PARSE_ERROR"
            case internalError = "INTERNAL_ERROR"
            case invalidTransaction = "INVALID_TRANSACTION"
            case unknownTransaction = "UNKNOWN_TRANSACTION"
            case timeoutError = "TIMEOUT_ERROR"
            case unknownError

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                let rawValue = try container.decode(String.self)
                self = ErrorCauseName(rawValue: rawValue) ?? .unknownError
            }
        }

        struct ErrorCause: Decodable {
            let name: ErrorCauseName
            let info: AnyDecodable?
        }

        let name: ErrorTypeName
        let cause: ErrorCause
    }
}
