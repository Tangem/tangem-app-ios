//
//  TestnetAPINodeInfoProvider.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 04/04/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct TestnetAPINodeInfoProvider {
    let blockchain: Blockchain
    let config: BlockchainSdkConfig

    func urls() -> [NodeInfo]? {
        guard blockchain.isTestnet else {
            return nil
        }

        let keysInfoProvider = APIKeysInfoProvider(blockchain: blockchain, config: config)
        switch blockchain {
        case .cosmos:
            return [
                .init(url: URL(string: "https://rest.seed-01.theta-testnet.polypore.xyz")!),
            ]
        case .near:
            return [
                .init(url: URL(string: "https://rpc.testnet.near.org")!),
            ]
        case .azero:
            return [
                .init(url: URL(string: "https://rpc.test.azero.dev")!),
                .init(url: URL(string: "aleph-zero-testnet-rpc.dwellir.com")!),
            ]
        case .ravencoin:
            return [
                .init(url: URL(string: "https://testnet.ravencoin.network/api")!),
            ]
        case .stellar:
            return [
                .init(url: URL(string: "https://horizon-testnet.stellar.org")!),
            ]
        case .tron:
            return [
                .init(url: URL(string: "https://nile.trongrid.io")!),
            ]
        case .algorand:
            return [
                .init(url: URL(string: "https://testnet-api.algonode.cloud")!),
            ]
        case .aptos:
            return [
                .init(url: URL(string: "https://fullnode.testnet.aptoslabs.com")!),
            ]
        case .hedera:
            return [
                .init(url: URL(string: "https://testnet.mirrornode.hedera.com/api/v1")!),
                .init(
                    url: URL(string: "https://pool.arkhia.io/hedera/testnet/api/v1")!,
                    keyInfo: keysInfoProvider.apiKeys(for: .arkhiaHedera)
                ),
            ]
        case .ton:
            return [
                .init(
                    url: URL(string: "https://testnet.toncenter.com/api/v2")!,
                    keyInfo: keysInfoProvider.apiKeys(for: .ton)
                ),
            ]
        case .chia:
            return [
                .init(
                    url: URL(string: "https://kraken.fireacademy.io/leaflet-testnet10/")!,
                    keyInfo: keysInfoProvider.apiKeys(for: .fireAcademy)
                ),
            ]
        case .ethereum:
            return [
                .init(url: URL(string: "https://eth-goerli.nownodes.io/\(config.nowNodesApiKey)")!),
                .init(url: URL(string: "https://goerli.infura.io/v3/\(config.infuraProjectId)")!),
            ]
        case .ethereumClassic:
            return [
                .init(url: URL(string: "https://rpc.mordor.etccooperative.org")!),
            ]
        case .ethereumPoW:
            return [
                .init(url: URL(string: "https://iceberg.ethereumpow.org")!),
            ]
        case .bsc:
            return [
                .init(url: URL(string: "https://data-seed-prebsc-1-s1.binance.org:8545")!),
            ]
        case .polygon:
            return [
                .init(url: URL(string: "https://rpc-amoy.polygon.technology")!),
            ]
        case .avalanche:
            return [
                .init(url: URL(string: "https://api.avax-test.network/ext/bc/C/rpc")!),
            ]
        case .fantom:
            return [
                .init(url: URL(string: "https://rpc.testnet.fantom.network")!),
            ]
        case .arbitrum:
            return [
                .init(url: URL(string: "https://goerli-rollup.arbitrum.io/rpc")!),
            ]
        case .optimism:
            return [
                .init(url: URL(string: "https://goerli.optimism.io")!),
            ]
        case .kava:
            return [
                .init(url: URL(string: "https://evm.testnet.kava.io")!),
            ]
        case .telos:
            return [
                .init(url: URL(string: "https://telos-evm-testnet.rpc.thirdweb.com")!),
            ]
        case .decimal:
            return [
                .init(url: URL(string: "https://testnet-val.decimalchain.com/web3")!),
            ]
        case .xdc:
            return [
                .init(url: URL(string: "https://rpc.apothem.network")!),
            ]
        case .shibarium:
            return [
                .init(url: URL(string: "https://puppynet.shibrpc.com")!),
            ]
        case .areon:
            return [
                .init(url: URL(string: "https://testnet-rpc.areon.network")!),
                .init(url: URL(string: "https://testnet-rpc2.areon.network")!),
                .init(url: URL(string: "https://testnet-rpc3.areon.network")!),
                .init(url: URL(string: "https://testnet-rpc4.areon.network")!),
                .init(url: URL(string: "https://testnet-rpc5.areon.network")!),
            ]
        case .pulsechain:
            return [
                .init(url: URL(string: "https://rpc.v4.testnet.pulsechain.com")!),
                .init(url: URL(string: "https://pulsechain-testnet.publicnode.com")!),
                .init(url: URL(string: "https://rpc-testnet-pulsechain.g4mm4.io")!),
            ]
        case .aurora:
            return [
                .init(url: URL(string: "https://testnet.aurora.dev")!),
            ]
        case .manta:
            return [
                .init(url: URL(string: "https://pacific-rpc.testnet.manta.network/http/")!),
            ]
        case .zkSync:
            return [
                .init(url: URL(string: "https://sepolia.era.zksync.dev/")!),
            ]
        case .moonbeam:
            return [
                .init(url: URL(string: "https://moonbase-alpha.public.blastapi.io/")!),
                .init(url: URL(string: "https://moonbase-rpc.dwellir.com/")!),
                .init(url: URL(string: "https://rpc.api.moonbase.moonbeam.network/")!),
                .init(url: URL(string: "https://moonbase.unitedbloc.com/")!),
                .init(url: URL(string: "https://moonbeam-alpha.api.onfinality.io/public/")!),
            ]
        case .polygonZkEVM:
            return [
                .init(url: URL(string: "https://rpc.cardona.zkevm-rpc.com/")!),
            ]
        case .moonriver:
            return [
                .init(url: URL(string: "https://rpc.api.moonbase.moonbeam.network/")!),
            ]
        case .mantle:
            return [
                .init(url: URL(string: "https://rpc.testnet.mantle.xyz")!),
            ]
        case .flare:
            return [
                .init(url: URL(string: "https://coston2-api.flare.network/ext/C/rpc")!),
            ]
        case .taraxa:
            return [
                .init(url: URL(string: "https://rpc.testnet.taraxa.io")!),
            ]
        case .base:
            return [
                .init(url: URL(string: "https://sepolia.base.org")!),
                .init(url: URL(string: "https://rpc.notadegen.com/base/sepolia")!),
                .init(url: URL(string: "https://base-sepolia-rpc.publicnode.com")!),
            ]
        case .veChain:
            return [
                .init(url: URL(string: "https://testnet.vecha.in")!),
                .init(url: URL(string: "https://sync-testnet.vechain.org")!),
                .init(url: URL(string: "https://testnet.veblocks.net")!),
                .init(url: URL(string: "https://testnetc1.vechain.network")!),
            ]
        case .polkadot:
            return [
                .init(url: URL(string: "https://westend-rpc.polkadot.io")!),
            ]
        case .koinos:
            return [
                .init(url: URL(string: "https://harbinger-api.koinos.io")!),
            ]
        case .cyber:
            return [
                .init(url: URL(string: "https://cyber-testnet.alt.technology")!),
            ]
        case .blast:
            return [
                .init(url: URL(string: "https://sepolia.blast.io")!),
                .init(url: URL(string: "https://blast-sepolia.drpc.org")!),
                .init(url: URL(string: "https://blast-sepolia.blockpi.network/v1/rpc/public")!),
            ]
        case .sui:
            return [
                .init(url: URL(string: "https://fullnode.testnet.sui.io")!),
            ]
        case .sei:
            return [
                .init(url: URL(string: "https://rest.wallet.atlantic-2.sei.io")!),
            ]
        case .kaspa:
            return [
                .init(url: URL(string: "https://api-tn10.kaspa.org")!),
            ]
        case .energyWebEVM:
            return [
                .init(url: URL(string: "https://73799.rpc.thirdweb.com")!),
            ]
        case .core:
            return [
                .init(url: URL(string: "https://rpc.test.btcs.network")!),
            ]
        case .casper:
            return [
                .init(url: URL(string: "https://testnet.phantom-rpc.com/rpc")!),
            ]
        case .chiliz:
            return [
                .init(url: URL(string: "https://spicy-rpc.chiliz.com")!),
                .init(url: URL(string: "https://chiliz-spicy.publicnode.com/")!),
            ]
        case .odysseyChain:
            return [
                .init(url: URL(string: "https://testnode.dioneprotocol.com/ext/bc/D/rpc")!),
            ]
        case .bitrock:
            return [
                .init(url: URL(string: "https://testnet.bit-rock.io")!),
            ]
        case .apeChain:
            return [
                .init(url: URL(string: "https://curtis.rpc.caldera.xyz/http")!),
        case .sonic:
            return [
                .init(url: URL(string: "https://sonic-blaze-rpc.publicnode.com")!),
            ]
        // TODO: Refactor in IOS-6639
        case .bitcoin, .litecoin, .disChain, .rsk, .bitcoinCash, .binance, .cardano,
             .xrp, .ducatus, .tezos, .dogecoin, .solana, .kusama, .dash, .gnosis,
             .terraV1, .terraV2, .cronos, .octa, .playa3ullGames, .radiant, .joystream,
             .bittensor, .internetComputer, .filecoin, .energyWebX, .canxium, .xodex, .clore,
             .fact0rn:
            return nil
        }
    }
}
