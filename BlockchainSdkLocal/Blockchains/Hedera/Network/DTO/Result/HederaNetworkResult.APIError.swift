//
//  HederaNetworkResult.APIError.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 06.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension HederaNetworkResult {
    struct APIError: Decodable {
        struct Status: Decodable {
            let messages: [Message]
        }

        struct Message: Decodable {
            let message: String
            let detail: String?
            let data: String?
        }

        let _status: Status
    }
}

// MARK: - LocalizedError protocol conformance

extension HederaNetworkResult.APIError: LocalizedError {
    var errorDescription: String? {
        return _status
            .messages
            .map(\.message)
            .joined(separator: "; ")
    }
}
