//
//  Blockchain+AllCases.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 24.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public extension Blockchain {
    /// Temporary solution unlit we removed `testnet` flag from a `case` blockchain
    static var allMainnetCases: [Blockchain] {
        // Did you get a compilation error here? If so, add your new blockchain to the array below
        switch Blockchain.bitcoin(testnet: false) {
        case .bitcoin: break
        case .litecoin: break
        case .stellar: break
        case .ethereum: break
        case .ethereumClassic: break
        case .rsk: break
        case .bitcoinCash: break
        case .binance: break
        case .cardano: break
        case .xrp: break
        case .ducatus: break
        case .tezos: break
        case .dogecoin: break
        case .bsc: break
        case .polygon: break
        case .avalanche: break
        case .solana: break
        case .fantom: break
        case .polkadot: break
        case .kusama: break
        case .azero: break
        case .tron: break
        case .arbitrum: break
        case .dash: break
        case .gnosis: break
        case .optimism: break
        case .disChain: break
        case .ethereumPoW: break
        case .ton: break
        case .kava: break
        case .kaspa: break
        case .ravencoin: break
        case .cosmos: break
        case .terraV1: break
        case .terraV2: break
        case .cronos: break
        case .telos: break
        case .octa: break
        case .chia: break
        case .near: break
        case .decimal: break
        case .veChain: break
        case .xdc: break
        case .algorand: break
        case .shibarium: break
        case .aptos: break
        case .hedera: break
        case .areon: break
        case .playa3ullGames: break
        case .pulsechain: break
        case .aurora: break
        case .manta: break
        case .zkSync: break
        case .moonbeam: break
        case .polygonZkEVM: break
        case .moonriver: break
        case .mantle: break
        case .flare: break
        case .taraxa: break
        case .radiant: break
        case .base: break
        case .joystream: break
        case .bittensor: break
        case .koinos: break
        case .internetComputer: break
        case .cyber: break
        case .blast: break
        case .sui: break
        case .filecoin: break
        case .sei: break
        case .energyWebEVM: break
        case .energyWebX: break
        case .core: break
        case .casper: break
            // READ BELOW:
            //
            // Did you get a compilation error here? If so, add your new blockchain to the array below
        }
        
        return [
            .ethereum(testnet: false),
            .ethereumClassic(testnet: false),
            .litecoin,
            .bitcoin(testnet: false),
            .bitcoinCash,
            .xrp(curve: .secp256k1),
            .rsk,
            .binance(testnet: false),
            .tezos(curve: .secp256k1),
            .stellar(curve: .ed25519_slip0010, testnet: false),
            .cardano(extended: false),
            .ducatus,
            .dogecoin,
            .bsc(testnet: false),
            .polygon(testnet: false),
            .avalanche(testnet: false),
            .solana(curve: .ed25519_slip0010, testnet: false),
            .polkadot(curve: .ed25519_slip0010, testnet: false),
            .kusama(curve: .ed25519_slip0010),
            .azero(curve: .ed25519_slip0010, testnet: false),
            .fantom(testnet: false),
            .tron(testnet: false),
            .arbitrum(testnet: false),
            .dash(testnet: false),
            .gnosis,
            .optimism(testnet: false),
            .disChain,
            .ethereumPoW(testnet: false),
            .ton(curve: .ed25519_slip0010, testnet: false),
            .kava(testnet: false),
            .kaspa(testnet: false),
            .ravencoin(testnet: false),
            .cosmos(testnet: false),
            .terraV1,
            .terraV2,
            .cronos,
            .telos(testnet: false),
            .octa,
            .chia(testnet: false),
            .near(curve: .ed25519_slip0010, testnet: false),
            .decimal(testnet: false),
            .veChain(testnet: false),
            .algorand(curve: .ed25519_slip0010, testnet: false),
            .xdc(testnet: false),
            .shibarium(testnet: false),
            .aptos(curve: .ed25519_slip0010, testnet: false),
            .hedera(curve: .ed25519_slip0010, testnet: false),
            .areon(testnet: false),
            .playa3ullGames,
            .pulsechain(testnet: false),
            .aurora(testnet: false),
            .manta(testnet: false),
            .zkSync(testnet: false),
            .moonbeam(testnet: false),
            .polygonZkEVM(testnet: false),
            .moonriver(testnet: false),
            .mantle(testnet: false),
            .flare(testnet: false),
            .taraxa(testnet: false),
            .radiant(testnet: false),
            .base(testnet: false),
            .joystream(curve: .ed25519_slip0010),
            .bittensor(curve: .ed25519_slip0010),
            .koinos(testnet: false),
            .internetComputer,
            .cyber(testnet: false),
            .blast(testnet: false),
            .sui(curve: .ed25519_slip0010, testnet: false),
            .filecoin,
            .sei(testnet: false),
            .energyWebEVM(testnet: false),
            .energyWebX(curve: .ed25519_slip0010),
            .core(testnet: false),
            .casper(testnet: false),
        ]
    }
}
