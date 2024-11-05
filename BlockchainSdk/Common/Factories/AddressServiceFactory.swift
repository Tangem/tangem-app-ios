//
//  AddressServiceFactory.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 13.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BitcoinCore
import WalletCore

public struct AddressServiceFactory {
    private let blockchain: Blockchain

    public init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }

    public func makeAddressService() -> AddressService {
        let isTestnet = blockchain.isTestnet

        switch blockchain {
        case .bitcoin:
            let network: BitcoinNetwork = isTestnet ? .testnet : .mainnet
            let networkParams = network.networkParams
            return BitcoinAddressService(networkParams: networkParams)
        case .litecoin:
            return BitcoinAddressService(networkParams: LitecoinNetworkParams())
        case .stellar:
            return StellarAddressService()
        case .ethereum,
             .ethereumClassic,
             .ethereumPoW,
             .disChain,
             .bsc,
             .polygon,
             .avalanche,
             .fantom,
             .arbitrum,
             .gnosis,
             .optimism,
             .kava,
             .cronos,
             .telos,
             .octa,
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
             .base,
             .cyber,
             .blast,
             .energyWebEVM,
             .core,
             .canxium:
            return EthereumAddressService()
        case .rsk:
            return RskAddressService()
        case .bitcoinCash:
            let networkParams: INetwork = isTestnet ? BitcoinCashTestNetworkParams() : BitcoinCashNetworkParams()
            return BitcoinCashAddressService(networkParams: networkParams)
        case .binance:
            return BinanceAddressService(testnet: isTestnet)
        case .cardano(let extended):
            if extended {
                return WalletCoreAddressService(coin: .cardano)
            }
            return CardanoAddressService()
        case .xrp(let curve):
            return XRPAddressService(curve: curve)
        case .tezos(let curve):
            return TezosAddressService(curve: curve)
        case .dogecoin:
            return BitcoinLegacyAddressService(networkParams: DogecoinNetworkParams())
        case .solana:
            return SolanaAddressService()
        case .polkadot(let curve, _):
            return PolkadotAddressService(network: isTestnet ? .westend(curve: curve) : .polkadot(curve: curve))
        case .kusama(let curve):
            return PolkadotAddressService(network: .kusama(curve: curve))
        case .azero(let curve, let isTestnet):
            return PolkadotAddressService(network: .azero(curve: curve, testnet: isTestnet))
        case .tron:
            return TronAddressService()
        case .dash:
            return BitcoinLegacyAddressService(
                networkParams: isTestnet ? DashTestNetworkParams() : DashMainNetworkParams()
            )
        case .kaspa:
            return KaspaAddressService(isTestnet: isTestnet)
        case .ravencoin:
            let networkParams: INetwork = isTestnet ? RavencoinTestNetworkParams() : RavencoinMainNetworkParams()
            return BitcoinLegacyAddressService(networkParams: networkParams)
        case .cosmos,
             .terraV1,
             .terraV2,
             .veChain,
             .internetComputer,
             .algorand,
             .sei:
            return WalletCoreAddressService(blockchain: blockchain)
        case .ton:
            return TonAddressService()
        case .aptos:
            return AptosCoreAddressService()
        case .ducatus:
            return BitcoinLegacyAddressService(networkParams: DucatusNetworkParams())
        case .chia:
            return ChiaAddressService(isTestnet: isTestnet)
        case .near:
            return NEARAddressService()
        case .decimal:
            return DecimalAddressService()
        case .xdc:
            return XDCAddressService()
        case .hedera:
            return HederaAddressService(isTestnet: isTestnet)
        case .radiant:
            return RadiantAddressService()
        case .joystream(let curve):
            return PolkadotAddressService(network: .joystream(curve: curve))
        case .bittensor(let curve):
            return PolkadotAddressService(network: .bittensor(curve: curve))
        case .koinos:
            let network: BitcoinNetwork = isTestnet ? .testnet : .mainnet
            return KoinosAddressService(networkParams: network.networkParams)
        case .sui:
            return SuiAddressService()
        case .filecoin:
            return WalletCoreAddressService(blockchain: .filecoin)
        case .energyWebX(let curve):
            return PolkadotAddressService(network: .energyWebX(curve: curve))
        }
    }
}
