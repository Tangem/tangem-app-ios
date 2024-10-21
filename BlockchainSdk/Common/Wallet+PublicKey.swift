//
//  Wallet+PublicKey.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 30.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

extension Wallet {
    public struct PublicKey: Codable, Hashable {
        public let seedKey: Data
        public let derivationType: DerivationType?

        /// Derived or non-derived key that should be used to create an address in a blockchain
        public var blockchainKey: Data {
            switch derivationType {
            case .none:
                return seedKey
            case .plain(let derivationKey):
                return derivationKey.extendedPublicKey.publicKey
            case .double(let first, let second):
                return CardanoUtil().extendPublicKey(first.extendedPublicKey, with: second.extendedPublicKey)
            }
        }

        public var derivationPath: DerivationPath? {
            derivationType?.hdKey.path
        }

        public init(seedKey: Data, derivationType: DerivationType?) {
            self.seedKey = seedKey
            self.derivationType = derivationType
        }
    }
}

extension Wallet.PublicKey {
    public enum DerivationType: Codable, Hashable {
        case plain(HDKey)

        /// Used only for Cardano
        case double(first: HDKey, second: HDKey)
        
        public var hdKey: HDKey {
            switch self {
            case .plain(let derivationKey):
                return derivationKey
            case .double(let derivationKey, _):
                return derivationKey
            }
        }
    }
    
    public struct HDKey: Codable, Hashable {
        public let path: DerivationPath
        public let extendedPublicKey: ExtendedPublicKey

        public init(path: DerivationPath, extendedPublicKey: ExtendedPublicKey) {
            self.path = path
            self.extendedPublicKey = extendedPublicKey
        }
    }
}
