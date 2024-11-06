//
//  TransactionParamsBuilder.swift
//  Tangem
//
//  Created by Andrey Chukavin on 21.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct TransactionParamsBuilder {
    private let blockchain: Blockchain

    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }

    func transactionParameters(value: String) throws -> TransactionParams {
        assert(!value.isEmpty, "Have to be checked before validation")

        switch blockchain {
        case .binance:
            return BinanceTransactionParams(memo: value)
        case .xrp:
            if let destinationTag = UInt32(value) {
                return XRPTransactionParams(destinationTag: destinationTag)
            } else {
                throw TransactionParamsBuilderError.invalidMemoDestinationTag
            }
        case .stellar:
            if let memoID = UInt64(value) {
                return StellarTransactionParams(memo: .id(memoID))
            } else {
                return StellarTransactionParams(memo: .text(value))
            }
        case .ton:
            return TONTransactionParams(memo: value)
        case .cosmos, .terraV1, .terraV2, .sei:
            return CosmosTransactionParams(memo: value)
        case .algorand:
            return AlgorandTransactionParams(nonce: value)
        case .hedera:
            return HederaTransactionParams(memo: value)
        case .internetComputer:
            if let memo = UInt64(value) {
                return ICPTransactionParams(memo: memo)
            } else {
                throw TransactionParamsBuilderError.invalidMemoDestinationTag
            }
        case .bitcoin,
             .litecoin,
             .ethereum,
             .ethereumPoW,
             .disChain,
             .ethereumClassic,
             .rsk,
             .bitcoinCash,
             .cardano,
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
             .kava,
             .kaspa,
             .ravencoin,
             .cronos,
             .telos,
             .octa,
             .chia,
             .near,
             .decimal,
             .veChain,
             .xdc,
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
             .cyber,
             .blast,
             .filecoin,
             .sui,
             .energyWebEVM,
             .energyWebX,
             .core,
             .canxium,
             .casper:
            throw TransactionParamsBuilderError.extraIdNotSupported
        }
    }
}

enum TransactionParamsBuilderError: LocalizedError {
    case invalidMemoDestinationTag
    case extraIdNotSupported

    var errorDescription: String? {
        switch self {
        case .invalidMemoDestinationTag:
            return Localization.sendMemoDestinationTagError
        case .extraIdNotSupported:
            return "Blockchain don't support the extra id"
        }
    }
}
