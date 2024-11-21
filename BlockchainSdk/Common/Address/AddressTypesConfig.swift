//
//  AddressTypesConfig.swift
//  Tangem
//
//  Created by Sergey Balashov on 24.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct AddressTypesConfig {
    func types(for blockchain: Blockchain) -> [AddressType] {
        switch blockchain {
        case .bitcoin:
            return [.default, .legacy]
        case .litecoin:
            return [.default, .legacy]
        case .bitcoinCash:
            return [.default, .legacy]
        case .cardano:
            return [.default, .legacy]
        case .decimal:
            return [.default, .legacy]
        case .xdc:
            return [.default, .legacy]
        case .stellar,
             .solana,
             .ethereum,
             .ethereumPoW,
             .disChain,
             .ethereumClassic,
             .rsk,
             .binance,
             .xrp,
             .ducatus,
             .tezos,
             .dogecoin,
             .bsc,
             .polygon,
             .avalanche,
             .fantom,
             .polkadot,
             .kusama,
             .azero,
             .tron,
             .arbitrum,
             .dash,
             .gnosis,
             .optimism,
             .ton,
             .kava,
             .kaspa,
             .ravencoin,
             .cosmos,
             .terraV1, .terraV2,
             .cronos,
             .telos,
             .octa,
             .chia,
             .near,
             .veChain,
             .algorand,
             .shibarium,
             .aptos,
             .hedera,
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
             .radiant,
             .base,
             .joystream,
             .bittensor,
             .internetComputer,
             .koinos,
             .cyber,
             .blast,
             .sui,
             .filecoin,
             .sei,
             .energyWebEVM,
             .energyWebX,
             .core,
             .canxium,
             .casper,
             .chiliz,
             .clore:
            return [.default]
        }
    }
}
