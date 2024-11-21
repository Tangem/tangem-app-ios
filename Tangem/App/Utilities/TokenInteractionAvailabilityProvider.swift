//
//  TokenInteractionAvailabilityProvider.swift
//  Tangem
//
//  Created by Andrey Fedorov on 16.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

/// Determines which UI (user) interactions are available for a given token.
struct TokenInteractionAvailabilityProvider {
    private let walletModel: WalletModel

    init(walletModel: WalletModel) {
        self.walletModel = walletModel
    }

    func isActionButtonsAvailable() -> Bool {
        return defaultInteractionAvailability()
    }

    func isContextMenuAvailable() -> Bool {
        let hasRequirements = walletModel.assetRequirementsManager?.hasRequirements(for: walletModel.amountType) ?? false
        return !hasRequirements && defaultInteractionAvailability()
    }

    func isTokenDetailsAvailable() -> Bool {
        return defaultInteractionAvailability()
    }

    private func defaultInteractionAvailability() -> Bool {
        switch walletModel.wallet.blockchain {
        case .bitcoin,
             .litecoin,
             .stellar,
             .ethereum,
             .ethereumPoW,
             .disChain,
             .ethereumClassic,
             .rsk,
             .bitcoinCash,
             .binance,
             .cardano,
             .xrp,
             .ducatus,
             .tezos,
             .dogecoin,
             .bsc,
             .polygon,
             .avalanche,
             .solana,
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
             .terraV1,
             .terraV2,
             .cronos,
             .telos,
             .octa,
             .chia,
             .near,
             .decimal,
             .veChain,
             .xdc,
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
             .bittensor,
             .joystream,
             .koinos,
             .internetComputer,
             .cyber,
             .blast,
             .filecoin,
             .sei,
             .sui,
             .energyWebEVM,
             .energyWebX,
             .core,
             .canxium,
             .casper,
             .chiliz:
            // Checking that we have at least one valid (non-empty) address
            //
            // If necessary, add more specific conditions for newly added blockchains
            return walletModel.wallet.addresses.contains { !$0.value.isEmpty }
        }
    }
}
