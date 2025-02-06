//
//  VisaError.swift
//  TangemVisa
//
//  Created by Andrew Son on 04/02/25.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum VisaError: LocalizedError {
    case failedToCreateDerivation
    case failedToCreateAddress(Error)

    public var errorDescription: String? {
        switch self {
        case .failedToCreateDerivation:
            return "Derivation error. Please contact support"
        case .failedToCreateAddress:
            return "Address creation error. Please contact support"
        }
    }
}
