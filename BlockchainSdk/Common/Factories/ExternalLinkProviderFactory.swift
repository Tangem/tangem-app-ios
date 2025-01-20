//
//  ExternalLinkProviderFactory.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 06.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExternalLinkProviderFactory {
    public init() {}

    public func makeProvider(for blockchain: Blockchain) -> ExternalLinkProvider {
        let isTestnet = blockchain.isTestnet

        switch blockchain {
        case .bitcoin:
            return BitcoinExternalLinkProvider(isTestnet: isTestnet)
        case .litecoin:
            return LitecoinExternalLinkProvider()
        case .stellar:
            return StellarExternalLinkProvider(isTestnet: isTestnet)
        case .ethereum:
            return EthereumExternalLinkProvider(isTestnet: isTestnet)
        case .ethereumPoW:
            return EthereumPoWExternalLinkProvider(isTestnet: isTestnet)
        case .disChain:
            return DisChainExternalLinkProvider()
        case .ethereumClassic:
            return EthereumClassicExternalLinkProvider(isTestnet: isTestnet)
        case .rsk:
            return RSKExternalLinkProvider()
        case .bitcoinCash:
            return BitcoinCashExternalLinkProvider(isTestnet: isTestnet)
        case .binance:
            return BinanceExternalLinkProvider(isTestnet: isTestnet)
        case .cardano:
            return CardanoExternalLinkProvider()
        case .xrp:
            return XRPExternalLinkProvider()
        case .ducatus:
            return DucatusExternalLinkProvider()
        case .tezos:
            return TezosExternalLinkProvider()
        case .dogecoin:
            return DogecoinExternalLinkProvider()
        case .bsc:
            return BSCExternalLinkProvider(isTestnet: isTestnet)
        case .polygon:
            return PolygonExternalLinkProvider(isTestnet: isTestnet)
        case .avalanche:
            return AvalancheExternalLinkProvider(isTestnet: isTestnet)
        case .solana:
            return SolanaExternalLinkProvider(isTestnet: isTestnet)
        case .fantom:
            return FantomExternalLinkProvider(isTestnet: isTestnet)
        case .polkadot:
            return PolkadotExternalLinkProvider(isTestnet: isTestnet)
        case .kusama:
            return KusamaExternalLinkProvider()
        case .azero:
            return AzeroExternalLinkProvider()
        case .tron:
            return TronExternalLinkProvider(isTestnet: isTestnet)
        case .arbitrum:
            return ArbitrumExternalLinkProvider(isTestnet: isTestnet)
        case .dash:
            return DashExternalLinkProvider(isTestnet: isTestnet)
        case .gnosis:
            return GnosisExternalLinkProvider()
        case .optimism:
            return OptimismExternalLinkProvider(isTestnet: isTestnet)
        case .ton:
            return TONExternalLinkProvider(isTestnet: isTestnet)
        case .kava:
            return KavaExternalLinkProvider(isTestnet: isTestnet)
        case .kaspa:
            return KaspaExternalLinkProvider(isTestnet: isTestnet)
        case .ravencoin:
            return RavencoinExternalLinkProvider(isTestnet: isTestnet)
        case .cosmos:
            return CosmosExternalLinkProvider(isTestnet: isTestnet)
        case .terraV1:
            return TerraV1ExternalLinkProvider()
        case .terraV2:
            return TerraV2ExternalLinkProvider()
        case .cronos:
            return CronosExternalLinkProvider()
        case .telos:
            return TelosExternalLinkProvider(isTestnet: isTestnet)
        case .octa:
            return OctaExternalLinkProvider()
        case .chia:
            return ChiaExternalLinkProvider(isTestnet: isTestnet)
        case .near:
            return NEARExternalLinkProvider(isTestnet: isTestnet)
        case .decimal:
            return DecimalExternalLinkProvider(isTestnet: isTestnet)
        case .veChain:
            return VeChainExternalLinkProvider(isTestnet: isTestnet)
        case .xdc:
            return XDCExternalLinkProvider(isTestnet: isTestnet)
        case .algorand:
            return AlgorandExternalLinkProvider(isTestnet: isTestnet)
        case .shibarium:
            return ShibariumExternalLinkProvider(isTestnet: isTestnet)
        case .aptos:
            return AptosExternalLinkProvider(isTestnet: isTestnet)
        case .hedera:
            return HederaExternalLinkProvider(isTestnet: isTestnet)
        case .areon:
            return AreonExternalLinkProvider()
        case .playa3ullGames:
            return Playa3ullGamesExternalLinkProvider()
        case .pulsechain:
            return PulsechainExternalLinkProvider(isTestnet: isTestnet)
        case .aurora:
            return AuroraExternalLinkProvider(isTestnet: isTestnet)
        case .manta:
            return MantaExternalLinkProvider(isTestnet: isTestnet)
        case .zkSync:
            return ZkSyncExternalLinkProvider(isTestnet: isTestnet)
        case .moonbeam:
            return MoonbeamExternalLinkProvider(isTestnet: isTestnet)
        case .polygonZkEVM:
            return PolygonZkEvmExternalLinkProvider(isTestnet: isTestnet)
        case .moonriver:
            return MoonriverExternalLinkProvider(isTestnet: isTestnet)
        case .mantle:
            return MantleExternalLinkProvider(isTestnet: isTestnet)
        case .flare:
            return FlareExternalLinkProvider(isTestnet: isTestnet)
        case .taraxa:
            return TaraxaExternalLinkProvider(isTestnet: isTestnet)
        case .radiant:
            return RadiantExternalLinkProvider()
        case .base:
            return BaseExternalLinkProvider(isTestnet: isTestnet)
        case .joystream:
            return JoystreamExternalLinkProvider()
        case .bittensor:
            return BittensorExternalLinkProvider()
        case .koinos:
            return KoinosExternalLinkProvider(isTestnet: isTestnet)
        case .internetComputer:
            return ICPExternalLinkProvider()
        case .cyber:
            return CyberExternalLinkProvider(isTestnet: isTestnet)
        case .blast:
            return BlastExternalLinkProvider(isTestnet: isTestnet)
        case .sui:
            return SuiExternalLinkProvider(isTestnet: isTestnet)
        case .filecoin:
            return FilecoinExternalLinkProvider()
        case .sei:
            return SeiExternalLinkProvider(isTestnet: isTestnet)
        case .energyWebEVM:
            return EnergyWebChainExternalLinkProvider(isTestnet: isTestnet)
        case .energyWebX:
            return EnergyWebXExternalLinkProvider(isTestnet: isTestnet)
        case .core:
            return CoreExternalLinkProvider(isTestnet: isTestnet)
        case .canxium:
            return CanxiumExternalLinkProvider()
        case .casper:
            return CasperExternalLinkProvider(isTestnet: isTestnet)
        case .chiliz:
            return ChilizExternalLinkProvider(isTestnet: isTestnet)
        case .xodex:
            return XodexExternalLinkProvider()
        case .clore:
            return CloreExternalLinkProvider()
        case .fact0rn:
            return Fact0rnExternalLinkProvider()
        case .odysseyChain:
            return OdysseyChainExternalLinkProvider(isTestnet: isTestnet)
        case .bitrock:
            return BitrockExternalLinkProvider(isTestnet: isTestnet)
        }
    }
}
