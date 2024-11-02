//
//  TWPublicKeyType+.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 30.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
import BlockchainSdk

extension PublicKeyType {
    /// Сonstructor that maps the sdk blockchain type into the TrustWallet public key type
    /// - Warning: Not for production use, use only for unit tests.
    init(_ blockchain: BlockchainSdk.Blockchain) throws {
        switch blockchain {
        case .bitcoin,
             .litecoin,
             .binance,
             .dash,
             .dogecoin,
             .bitcoinCash,
             .ravencoin,
             .cosmos,
             .terraV1,
             .terraV2,
             .radiant,
             .koinos,
             .filecoin,
             .sei:
            self = PublicKeyType.secp256k1
        case .ethereum,
             .bsc,
             .tron,
             .polygon,
             .arbitrum,
             .avalanche,
             .ethereumClassic,
             .optimism,
             .fantom,
             .kava,
             .decimal,
             .veChain,
             .xdc,
             .shibarium,
             .areon,
             .playa3ullGames,
             .pulsechain,
             .aurora,
             .manta,
             .zkSync,
             .moonbeam,
             .polygonZkEVM,
             .moonriver,
             .mantle,
             .flare,
             .taraxa,
             .internetComputer,
             .base,
             .blast,
             .cyber,
             .energyWebEVM,
             .core,
             .canxium:
            self = PublicKeyType.secp256k1Extended
        case .stellar,
             .ton,
             .solana,
             .polkadot,
             .kusama,
             .near,
             .algorand,
             .aptos,
             .sui,
             .energyWebX:
            self = PublicKeyType.ed25519
        case .cardano(let extended):
            self = extended ? PublicKeyType.ed25519Cardano : .ed25519
        case .hedera(let curve, _):
            switch curve {
            case .secp256k1:
                self = PublicKeyType.secp256k1
            case .ed25519, .ed25519_slip0010:
                self = PublicKeyType.ed25519
            default:
                throw NSError.makeUnsupportedCurveError(for: blockchain)
            }
        case .xrp(let curve):
            switch curve {
            case .secp256k1:
                self = PublicKeyType.secp256k1
            case .ed25519, .ed25519_slip0010:
                self = PublicKeyType.ed25519
            default:
                throw NSError.makeUnsupportedCurveError(for: blockchain)
            }
        case .tezos(let curve):
            switch curve {
            case .ed25519, .ed25519_slip0010:
                self = .ed25519
            default:
                throw NSError.makeUnsupportedCurveError(for: blockchain)
            }
        case .ethereumPoW,
             .disChain,
             .rsk,
             .ducatus,
             .azero,
             .gnosis,
             .kaspa,
             .cronos,
             .telos,
             .octa,
             .chia,
             .joystream,
             .bittensor:
            throw NSError.makeUnsupportedBlockchainError(for: blockchain)
        }
    }
}
