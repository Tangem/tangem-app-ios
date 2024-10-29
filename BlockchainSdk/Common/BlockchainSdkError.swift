//
//  BlockchainSdkError.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 27/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public enum BlockchainSdkError: Int, LocalizedError {
    // WARNING: Make sure to preserve the error codes when removing or inserting errors

    case signatureCountNotMatched = 0
    case failedToCreateMultisigScript = 1
    case failedToConvertPublicKey = 2
    case notImplemented = -1000
    case decodingFailed
    case failedToLoadFee
    case failedToLoadTxDetails
    case failedToFindTransaction
    case failedToFindTxInputs
    case feeForPushTxNotEnough
    case networkProvidersNotSupportsRbf
    case noAPIInfo

    // WARNING: Make sure to preserve the error codes when removing or inserting errors

    public var errorDescription: String? {
        switch self {
        case .failedToLoadFee:
            return Localization.commonFeeError
        case .signatureCountNotMatched, .notImplemented:
            // TODO: Replace with proper error message. Android sending instead of message just code, and client app decide what message to show to user
            return Localization.genericError
        default:
            return Localization.genericError
        }
    }

    @available(*, deprecated, message: "Use errorDescription and errorCode instead")
    public var errorDescriptionWithCode: String {
        switch self {
        case .failedToLoadFee:
            return Localization.commonFeeError
        case .signatureCountNotMatched, .notImplemented:
            // TODO: Replace with proper error message. Android sending instead of message just code, and client app decide what message to show to user
            return Localization.genericErrorCode(errorCodeDescription)
        default:
            return Localization.genericErrorCode(errorCodeDescription)
        }
    }

    private var errorCodeDescription: String {
        "blockchain_sdk_error \(rawValue)"
    }
}

extension BlockchainSdkError: ErrorCodeProviding {
    public var errorCode: Int {
        rawValue
    }
}

public enum NetworkServiceError: Error {
    case notAvailable
}
