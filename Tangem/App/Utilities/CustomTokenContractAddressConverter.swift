//
//  CustomTokenContractAddressConverter.swift
//  Tangem
//
//  Created by Andrey Fedorov on 19.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct CustomTokenContractAddressConverter {
    private let blockchain: Blockchain

    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }

    func convert(_ originalAddress: String, symbol: String?) -> String {
        switch blockchain {
        case .hedera:
            do {
                // This converter has quite strict rules for EVM to Hedera address conversion, and the conversion
                // will fail if the address is not EVM-like. See SolidityAddress.swift for implementation details.
                // In case of failure, we consider the address a not-EVM address and return it as is
                let converter = HederaTokenContractAddressConverter()
                return try converter.convertFromEVMToHedera(originalAddress)
            } catch {
                return originalAddress
            }
        case .cardano:
            do {
                let converter = CardanoTokenContractAddressService()
                return try converter.convertToFingerprint(address: originalAddress, symbol: symbol)
            } catch {
                return originalAddress
            }
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
             .chiliz,
             .xodex,
             .clore,
             .fact0rn,
             .odysseyChain,
             .bitrock:
            // Did you get a compilation error here? If so, check if the network supports multiple token contract address
            // formats (as Hedera does, for example) and add the appropriate conversion logic here if needed
            return originalAddress
        }
    }
}
