//
//  SendTransactionParametersBuilder.swift
//  Tangem
//
//  Created by Andrey Chukavin on 21.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct SendTransactionParametersBuilder {
    private let blockchain: Blockchain

    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }

    func transactionParameters(from value: String) throws -> TransactionParams? {
        if value.isEmpty {
            return nil
        }

        switch blockchain {
        case .binance:
            return BinanceTransactionParams(memo: value)
        case .xrp:
            if let destinationTag = UInt32(value) {
                return XRPTransactionParams(destinationTag: destinationTag)
            } else {
                throw SendTransactionParametersBuilderError.invalidDestinationTag
            }
        case .stellar:
            if let memoID = UInt64(value) {
                return StellarTransactionParams(memo: .id(memoID))
            } else {
                return StellarTransactionParams(memo: .text(value))
            }
        case .ton:
            return TONTransactionParams(memo: value)
        case .cosmos, .terraV1, .terraV2:
            return CosmosTransactionParams(memo: value)
        case .algorand:
            return AlgorandTransactionParams(nonce: value)
        case .hedera:
            return HederaTransactionParams(memo: value)
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
             .taraxa:
            return nil
        }
    }
}

private enum SendTransactionParametersBuilderError {
    case invalidDestinationTag
}

extension SendTransactionParametersBuilderError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidDestinationTag:
            return Localization.sendMemoDestinationTagError
        }
    }
}
