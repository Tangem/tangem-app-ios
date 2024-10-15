//
//  TWCurve+.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 25.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
import BlockchainSdk

extension Curve {
    /// Сonstructor that maps the sdk blockchain curve into the TrustWallet Curve.
    /// - Warning: Not for production use, use only for unit tests.
    init(blockchain: BlockchainSdk.Blockchain) throws {
        switch blockchain {
        case .cardano(let extended):
            self = extended ? .ed25519ExtendedCardano : .ed25519
        default:
            switch blockchain.curve {
            case .secp256k1:
                self = .secp256k1
            case .ed25519_slip0010:
                self = .ed25519
            case .ed25519,
                 .secp256r1,
                 .bls12381_G2,
                 .bls12381_G2_AUG,
                 .bls12381_G2_POP,
                 .bip0340:
                throw NSError.makeUnsupportedCurveError(for: blockchain)
            }
        }
    }
}
