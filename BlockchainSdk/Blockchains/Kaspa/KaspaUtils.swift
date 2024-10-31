//
// KaspaUtils.swift
// BlockchainSdk
//
// Created by Sergei Iakovlev on 22.10.2024
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct KaspaUtils {
    enum KaspaHashType: String {
        case TransactionSigningHashECDSA
        case TransactionID
        case TransactionHash
        
        var data: Data {
            self.rawValue.data(using: .utf8)!
        }
    }
}
