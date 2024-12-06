//
//  CardAuthorizationProcessorError.swift
//  TangemVisa
//
//  Created by Andrew Son on 26.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum CardAuthorizationProcessorError: Error {
    case authorizationChallengeNotFound
    case invalidCardInput
    case networkError(Error)

    public var description: String {
        switch self {
        case .authorizationChallengeNotFound:
            return "Authorization challenge request not found"
        case .invalidCardInput:
            return "Invalid card input"
        case .networkError(let error):
            return "Underlying network error: \(error)"
        }
    }
}
