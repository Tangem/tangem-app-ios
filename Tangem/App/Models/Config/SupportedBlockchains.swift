//
//  SupportedBlockchains.swift
//  Tangem
//
//  Created by Sergey Balashov on 21.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

typealias SupportedBlockchainsSet = Set<Blockchain>

extension SupportedBlockchains {
    /// All currently supported mainnet blockchains for simple used.
    /// E.g. for the Token list.
    static var all: Set<Blockchain> {
        SupportedBlockchains(version: .v1).blockchains()
    }

    /// Blockchains which don't include in supported blockchains by default
    static var testableIDs: Set<String> {
        // Here version isn't important because we take only coinId
        return Set(SupportedBlockchains(version: .v1).testableBlockchains().map { $0.coinId })
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

        let betaTestingBlockchains = FeatureStorage().supportedBlockchainsIds.compactMap { id in
            testableBlockchains().first { $0.coinId == id }
        }

        return mainnetBlockchains.union(Set(betaTestingBlockchains))
    }

    /// Blockchains for test. They don't include in supported blockchains by default
    private func testableBlockchains() -> Set<Blockchain> {
        [
            .telos(testnet: false),
            .azero(curve: version == .v2 ? .ed25519_slip0010 : .ed25519, testnet: false),
            .chia(testnet: false),
        ]
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
            .cardano(extended: version == .v2),
            .xrp(curve: .secp256k1),
            .rsk,
            .binance(testnet: false),
            .tezos(curve: version == .v2 ? .ed25519_slip0010 : .secp256k1),
            .stellar(curve: version == .v2 ? .ed25519_slip0010 : .ed25519, testnet: false),
            .dogecoin,
            .bsc(testnet: false),
            .polygon(testnet: false),
            .avalanche(testnet: false),
            .solana(curve: version == .v2 ? .ed25519_slip0010 : .ed25519, testnet: false),
            .polkadot(curve: version == .v2 ? .ed25519_slip0010 : .ed25519, testnet: false),
            .kusama(curve: version == .v2 ? .ed25519_slip0010 : .ed25519),
            .azero(curve: version == .v2 ? .ed25519_slip0010 : .ed25519, testnet: false),
            .fantom(testnet: false),
            .tron(testnet: false),
            .arbitrum(testnet: false),
            .gnosis,
            .dash(testnet: false),
            .optimism(testnet: false),
            .ton(curve: version == .v2 ? .ed25519_slip0010 : .ed25519, testnet: false),
            .kava(testnet: false),
            .kaspa,
            .ravencoin(testnet: false),
            .cosmos(testnet: false),
            .terraV1,
            .terraV2,
            .cronos,
            .octa,
            .chia(testnet: false),
            .ducatus,
        ]
    }

    private func testnetBlockchains() -> Set<Blockchain> {
        [
            .bitcoin(testnet: true),
            .ethereum(testnet: true),
            .ethereumClassic(testnet: true),
            .ethereumPoW(testnet: true),
            .binance(testnet: true),
            .stellar(curve: version == .v2 ? .ed25519_slip0010 : .ed25519, testnet: true),
            .bsc(testnet: true),
            .polygon(testnet: true),
            .avalanche(testnet: true),
            .solana(curve: version == .v2 ? .ed25519_slip0010 : .ed25519, testnet: true),
            .fantom(testnet: true),
            .polkadot(curve: version == .v2 ? .ed25519_slip0010 : .ed25519, testnet: true),
            .azero(curve: version == .v2 ? .ed25519_slip0010 : .ed25519, testnet: true),
            .tron(testnet: true),
            .arbitrum(testnet: true),
            .optimism(testnet: true),
            .ton(curve: version == .v2 ? .ed25519_slip0010 : .ed25519, testnet: true),
            .kava(testnet: true),
            .ravencoin(testnet: true),
            .cosmos(testnet: true),
            .octa,
            .chia(testnet: true),
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
