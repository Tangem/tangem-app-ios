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
    case wrongCard
    case missingOrderDataToSign
    case missingWallet
    case missingRootOTP
    case taskMissingDelegate
    case underlyingError(Error)

    var description: String {
        switch self {
        case .notImplemented: return "Not implemented"
        case .missingAccessCode: return "Missing access code"
        case .wrongCard: return "Wrong card tapped"
        case .missingOrderDataToSign: return "Failed to find order for account activation"
        case .missingWallet: return "Failed to find wallet on card"
        case .missingRootOTP: return "Failed to find root OTP"
        case .taskMissingDelegate: return "Activation task wasn't setup properly"
        case .underlyingError(let error):
            return "Underlying Visa Activation Error: \(error)"
        }
    }
}

public enum VisaAccessCodeValidationError: String, Error {
    case accessCodeIsTooShort
}
