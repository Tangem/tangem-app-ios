//
//  TangemInputAPIError.swift
//  Tangem
//
//  Created by Andrey Fedorov on 16.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// Server-side errors of validating the input parameters of the API.
struct TangemInputAPIError: Decodable {
    private enum CodingKeys: CodingKey {
        case statusCode
        case error
        case message
    }

    let statusCode: TangemAPIError.ErrorCode
    let error: String?
    let message: [String]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var messages: [String] = []

        if let errorMessages = try? container.decodeIfPresent([String].self, forKey: .message) {
            messages.append(contentsOf: errorMessages)
        }

        if let errorMessage = try? container.decodeIfPresent(String.self, forKey: .message) {
            messages.append(errorMessage)
        }

        statusCode = try container.decode(TangemAPIError.ErrorCode.self, forKey: .statusCode)
        error = try? container.decodeIfPresent(String.self, forKey: .error)
        message = messages
    }
}
