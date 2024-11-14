//
//  CasperConstants.swift
//  BlockchainSdk
//
//  Created by Alexander Skibin on 29.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

enum CasperConstants {
    // ED25519
    static let prefixED25519 = "01"
    static let lengthED25519 = 66

    // SECP256K1
    static let prefixSECP256K1 = "02"
    static let lengthSECP256K1 = 68

    static func getPrefix(by curve: EllipticCurve) -> String? {
        switch curve {
        case .ed25519, .ed25519_slip0010:
            return CasperConstants.prefixED25519
        case .secp256k1:
            return CasperConstants.prefixSECP256K1
        default:
            // Any curves not supported or will be added in the future
            return nil
        }
    }
}
