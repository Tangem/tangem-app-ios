//
//  TWPublicKey+.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 22.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemSdk
import WalletCore

extension PublicKey {
    convenience init?(tangemPublicKey: Data, publicKeyType: PublicKeyType) {
        let publicKey: Data

        switch publicKeyType {
        case .secp256k1:
            publicKey = Self.secp256k1Key(from: tangemPublicKey, compressed: true)
        case .secp256k1Extended:
            publicKey = Self.secp256k1Key(from: tangemPublicKey, compressed: false)
        default:
            publicKey = tangemPublicKey
        }

        self.init(data: publicKey, type: publicKeyType)
    }

    private static func secp256k1Key(from publicKey: Data, compressed: Bool) -> Data {
        do {
            let secp256k1Key = try Secp256k1Key(with: publicKey)
            return try compressed ? secp256k1Key.compress() : secp256k1Key.decompress()
        } catch {
            return publicKey
        }
    }
}
