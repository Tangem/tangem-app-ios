//
//  SupportedBlockchains.swift
//  Tangem
//
//  Created by Sergey Balashov on 21.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSdk

typealias SupportedBlockchainsSet = Set<Blockchain>

extension SupportedBlockchains {
    /// All currently supported mainnet blockchains for simple used.
    /// E.g. for the Token list.
    static var all: Set<Blockchain> {
        SupportedBlockchains(version: .v1).blockchains()
    }

    static var l2Blockchains: [Blockchain] {
        all
            .filter { $0.isL2EthereumNetwork }
            .sorted(by: \.displayName)
    }

    /// Blockchains which don't include in supported blockchains by default
    static var testableIDs: Set<String> {
        // Here version isn't important because we take only coinId
        return Set(SupportedBlockchains(version: .v1).testableBlockchains().map { $0.networkId })
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

        let betaTestingBlockchains = FeatureStorage.instance.supportedBlockchainsIds.compactMap { id in
            testableBlockchains().first { $0.networkId == id }
        }

        return mainnetBlockchains.union(Set(betaTestingBlockchains))
    }

    /// Blockchains for test. They don't include in supported blockchains by default
    private func testableBlockchains() -> Set<Blockchain> {
        [
        ]
    }

    private func mainnetBlockchains() -> Set<Blockchain> {
        [
            .ethereum(testnet: false),
            .ethereumClassic(testnet: false),
            .ethereumPoW(testnet: false),
            .disChain,
            .litecoin,
            .bitcoin(testnet: false),
            .bitcoinCash,
            .cardano(extended: version == .v2),
            .xrp(curve: .secp256k1),
            .rsk,
            .binance(testnet: false),
            .tezos(curve: version == .v2 ? .ed25519_slip0010 : .secp256k1),
            .stellar(curve: ed25519Curve(for: version), testnet: false),
            .dogecoin,
            .bsc(testnet: false),
            .polygon(testnet: false),
            .avalanche(testnet: false),
            .solana(curve: ed25519Curve(for: version), testnet: false),
            .polkadot(curve: ed25519Curve(for: version), testnet: false),
            .kusama(curve: ed25519Curve(for: version)),
            .azero(curve: ed25519Curve(for: version), testnet: false),
            .fantom(testnet: false),
            .tron(testnet: false),
            .arbitrum(testnet: false),
            .gnosis,
            .dash(testnet: false),
            .optimism(testnet: false),
            .ton(curve: ed25519Curve(for: version), testnet: false),
            .kava(testnet: false),
            .kaspa(testnet: false),
            .ravencoin(testnet: false),
            .cosmos(testnet: false),
            .terraV1,
            .terraV2,
            .cronos,
            .octa,
            .chia(testnet: false),
            .ducatus,
            .near(curve: ed25519Curve(for: version), testnet: false),
            .telos(testnet: false),
            .decimal(testnet: false),
            .veChain(testnet: false),
            .xdc(testnet: false),
            .shibarium(testnet: false),
            .algorand(curve: ed25519Curve(for: version), testnet: false),
            .aptos(curve: ed25519Curve(for: version), testnet: false),
            .hedera(curve: ed25519Curve(for: version), testnet: false),
            .areon(testnet: false),
            .pulsechain(testnet: false),
            .aurora(testnet: false),
            .base(testnet: false),
            .playa3ullGames,
            .zkSync(testnet: false),
            .moonbeam(testnet: false),
            .polygonZkEVM(testnet: false),
            .moonriver(testnet: false),
            .flare(testnet: false),
            .taraxa(testnet: false),
            .joystream(curve: ed25519Curve(for: version)),
            .manta(testnet: false),
            .radiant(testnet: false),
            .bittensor(curve: ed25519Curve(for: version)),
            .koinos(testnet: false),
            .mantle(testnet: false),
            .cyber(testnet: false),
            .blast(testnet: false),
            .filecoin,
            .internetComputer,
            .sei(testnet: false),
            .sui(curve: ed25519Curve(for: version), testnet: false),
            .energyWebEVM(testnet: false),
            .energyWebX(curve: ed25519Curve(for: version)),
            .core(testnet: false),
            .canxium,
            .casper(curve: .secp256k1, testnet: false),
            .chiliz(testnet: false),
            .xodex,
            .clore,
            .odysseyChain(testnet: false),
            .bitrock(testnet: false),
        ]
    }

    private func testnetBlockchains() -> Set<Blockchain> {
        [
            .bitcoin(testnet: true),
            .ethereum(testnet: true),
            .ethereumClassic(testnet: true),
            .ethereumPoW(testnet: true),
            .binance(testnet: true),
            .stellar(curve: ed25519Curve(for: version), testnet: true),
            .bsc(testnet: true),
            .polygon(testnet: true),
            .avalanche(testnet: true),
            .solana(curve: ed25519Curve(for: version), testnet: true),
            .fantom(testnet: true),
            .polkadot(curve: ed25519Curve(for: version), testnet: true),
            .azero(curve: ed25519Curve(for: version), testnet: true),
            .tron(testnet: true),
            .arbitrum(testnet: true),
            .optimism(testnet: true),
            .ton(curve: ed25519Curve(for: version), testnet: true),
            .kava(testnet: true),
            .ravencoin(testnet: true),
            .cosmos(testnet: true),
            .octa,
            .chia(testnet: true),
            .near(curve: ed25519Curve(for: version), testnet: true),
            .telos(testnet: true),
            .decimal(testnet: true),
            .veChain(testnet: true),
            .xdc(testnet: true),
            .algorand(curve: ed25519Curve(for: version), testnet: true),
            .shibarium(testnet: true),
            .aptos(curve: ed25519Curve(for: version), testnet: true),
            .hedera(curve: ed25519Curve(for: version), testnet: true),
            .areon(testnet: true),
            .pulsechain(testnet: true),
            .aurora(testnet: true),
            .manta(testnet: true),
            .zkSync(testnet: true),
            .moonbeam(testnet: true),
            .polygonZkEVM(testnet: true),
            .moonriver(testnet: true),
            .mantle(testnet: true),
            .flare(testnet: true),
            .taraxa(testnet: true),
            .base(testnet: true),
            .koinos(testnet: true),
            .cyber(testnet: true),
            .blast(testnet: true),
            .sei(testnet: true),
            .kaspa(testnet: true),
            .sui(curve: ed25519Curve(for: version), testnet: true),
            .energyWebEVM(testnet: true),
            .core(testnet: true),
            .odysseyChain(testnet: true),
            .bitrock(testnet: true),
        ]
    }

    private func ed25519Curve(for version: Version) -> EllipticCurve {
        switch version {
        case .v1:
            return .ed25519
        case .v2:
            return .ed25519_slip0010
        }
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
