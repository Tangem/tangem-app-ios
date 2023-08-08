//
//  SupportedBlockchains.swift
//  Tangem
//
//  Created by Sergey Balashov on 21.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

extension SupportedBlockchains {
    /// All currently supported mainnet blockchains for simple used.
    /// E.g. for the Token list.
    static var all: Set<Blockchain> {
        SupportedBlockchains(version: .v1).blockchains()
    }

    /// Blockchains which don't include in supported blockchains by default
    static var testable: Set<Blockchain> {
        Set(Blockchain.allMainnetCases)
            .subtracting(SupportedBlockchains(version: .v1).mainnetBlockchains())
    }
}

struct SupportedBlockchains {
    let version: Version

    /// Have to use this init `ONLY` in `UserWalletConfig`
    init(version: Version) {
        self.version = version
    }

    /// All `mainnet` supported blockchains
    /// May contains the `betaTestingBlockchains` for non production scheme
    func blockchains() -> Set<Blockchain> {
        if AppEnvironment.current.isTestnet {
            return testnetBlockchains()
        }

        let mainnetBlockchains = mainnetBlockchains()

        // For production return only mainnetBlockchains
        if AppEnvironment.current.isProduction {
            return mainnetBlockchains
        }

        let betaTestingBlockchains = FeatureStorage().supportedBlockchainsIds.compactMap { Blockchain(from: $0) }

        return mainnetBlockchains.union(Set(betaTestingBlockchains))
    }

    private func mainnetBlockchains() -> Set<Blockchain> {
        [
            .ethereum(testnet: false),
            .ethereumClassic(testnet: false),
            .ethereumPoW(testnet: false),
            .ethereumFair,
            .litecoin,
            .bitcoin(testnet: false),
            .bitcoinCash(testnet: false),
            .xrp(curve: .secp256k1),
            .rsk,
            .binance(testnet: false),
            .tezos(curve: version == .v2 ? .ed25519 : .secp256k1),
            .stellar(testnet: false),
            .cardano,
            .dogecoin,
            .bsc(testnet: false),
            .polygon(testnet: false),
            .avalanche(testnet: false),
            .solana(testnet: false),
            .polkadot(testnet: false),
            .kusama,
            .azero(testnet: false),
            .fantom(testnet: false),
            .tron(testnet: false),
            .arbitrum(testnet: false),
            .gnosis,
            .dash(testnet: false),
            .optimism(testnet: false),
            .ton(testnet: false),
            .kava(testnet: false),
            .kaspa,
            .ravencoin(testnet: false),
            .cosmos(testnet: false),
            .terraV1,
            .terraV2,
            .cronos,
            .octa
        ]
    }

    private func testnetBlockchains() -> Set<Blockchain> {
        [
            .bitcoin(testnet: true),
            .ethereum(testnet: true),
            .ethereumClassic(testnet: true),
            .ethereumPoW(testnet: true),
            .binance(testnet: true),
            .stellar(testnet: true),
            .bsc(testnet: true),
            .polygon(testnet: true),
            .avalanche(testnet: true),
            .solana(testnet: true),
            .fantom(testnet: true),
            .polkadot(testnet: true),
            .azero(testnet: true),
            .tron(testnet: true),
            .arbitrum(testnet: true),
            .optimism(testnet: true),
            .ton(testnet: true),
            .kava(testnet: true),
            .ravencoin(testnet: true),
            .cosmos(testnet: true),
            .octa
        ]
    }
}

extension SupportedBlockchains {
    enum Version {
        /// All legacy cards
        case v1

        /// Wallet 2.0
        case v2
    }
}
