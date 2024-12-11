//
//  VisaActivationError.swift
//  TangemApp
//
//  Created by Andrew Son on 20.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum VisaActivationError: Error, LocalizedError {
    case notImplemented
    case missingAccessCode
    case missingAccessToken
    case missingActiveCardSession
    case missingCustomerId
    case wrongCard
    case missingOrderDataToSign
    case missingWallet
    case missingRootOTP
    case taskMissingDelegate
    case missingOTPManager
    case underlyingError(Error)

    public var errorDescription: String? {
        switch self {
        case .notImplemented: return "Not implemented"
        case .missingAccessCode: return "Missing access code"
        case .missingAccessToken: return "Missing access token. Please authorize with your Visa card"
        case .missingActiveCardSession: return "Failed to find active NFC session"
        case .missingCustomerId: return "Missing essential data for Visa Activation. Contact to support"
        case .wrongCard: return "Wrong card tapped"
        case .missingOrderDataToSign: return "Failed to find order for account activation"
        case .missingWallet: return "Failed to find wallet on card"
        case .missingRootOTP: return "Failed to find root OTP"
        case .taskMissingDelegate: return "Activation task wasn't setup properly"
        case .missingOTPManager: return "Failed to find OTP manager"
        case .underlyingError(let error):
            return "Underlying Visa Activation Error: \(error.localizedDescription)"
        }
    }
}

public enum VisaAccessCodeValidationError: String, Error {
    case accessCodeIsTooShort
}
