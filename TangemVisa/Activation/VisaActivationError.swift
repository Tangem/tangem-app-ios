//
//  VisaActivationError.swift
//  TangemApp
//
//  Created by Andrew Son on 20.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum VisaActivationError: Error {
    case notImplemented
    case missingAccessCode
    case missingAccessToken
    case missingActiveCardSession
    case missingCustomerId
    case underlyingError(Error)

    var description: String {
        switch self {
        case .notImplemented: return "Not implemented"
        case .missingAccessCode: return "Missing access code"
        case .missingAccessToken: return "Missing access token. Please authorize with your Visa card"
        case .missingActiveCardSession: return "Failed to find active NFC session"
        case .missingCustomerId: return "Missing essential data for Visa Activation. Contact to support"
        case .underlyingError(let error):
            return "Underlying Visa Activation Error: \(error)"
        }
    }
}

public enum VisaAccessCodeValidationError: String, Error {
    case accessCodeIsTooShort
}
