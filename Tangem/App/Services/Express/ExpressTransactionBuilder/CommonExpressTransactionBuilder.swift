//
//  CommonExpressTransactionBuilder.swift
//  Tangem
//
//  Created by Sergey Balashov on 21.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress

struct CommonExpressTransactionBuilder: ExpressTransactionBuilder {
    func makeTransaction(wallet: WalletModel, data: ExpressTransactionData, fee: Fee) async throws -> BlockchainSdk.Transaction {
        let destination: TransactionCreatorDestination = try {
            switch data.transactionType {
            case .send:
                return .send(destination: data.destinationAddress)
            case .swap:
                if let txData = data.txData {
                    return .contractCall(contract: data.destinationAddress, data: Data(hexString: txData))
                }

                throw ExpressTransactionBuilderError.transactionDataForSwapOperationNotFound
            }
        }()

        var transaction = try await buildTransaction(
            wallet: wallet,
            amount: data.txValue,
            fee: fee,
            destination: destination
        )

        if let extraDestinationId = data.extraDestinationId, !extraDestinationId.isEmpty {
            // If we received a extraId then try to map it to specific TransactionParams
            transaction.params = try mapToTransactionParams(blockchain: wallet.tokenItem.blockchain, extraDestinationId: extraDestinationId)
        }

        return transaction
    }

    func makeApproveTransaction(wallet: WalletModel, data: ApproveTransactionData, fee: Fee) async throws -> BlockchainSdk.Transaction {
        guard wallet.ethereumNetworkProvider != nil else {
            throw ExpressTransactionBuilderError.approveImpossibleInNotEvmBlockchain
        }

        let transaction = try await buildTransaction(
            wallet: wallet,
            amount: 0, // For approve value isn't needed
            fee: fee,
            destination: .contractCall(contract: data.toContractAddress, data: data.txData)
        )

        return transaction
    }
}

private extension CommonExpressTransactionBuilder {
    func buildTransaction(
        wallet: WalletModel,
        amount: Decimal,
        fee: Fee,
        destination: TransactionCreatorDestination
    ) async throws -> BSDKTransaction {
        try await wallet.transactionCreator.buildTransaction(
            tokenItem: wallet.tokenItem,
            feeTokenItem: wallet.feeTokenItem,
            amount: amount,
            fee: fee,
            destination: destination
        )
    }

    func mapToTransactionParams(blockchain: Blockchain, extraDestinationId: String) throws -> TransactionParams? {
        switch blockchain {
        case .binance:
            return BinanceTransactionParams(memo: extraDestinationId)

        case .xrp:
            let destinationTag = UInt32(extraDestinationId)
            return XRPTransactionParams(destinationTag: destinationTag)

        case .stellar:
            if let memoId = UInt64(extraDestinationId) {
                return StellarTransactionParams(memo: .id(memoId))
            }

            return StellarTransactionParams(memo: .text(extraDestinationId))

        case .ton:
            return TONTransactionParams(memo: extraDestinationId)

        case .cosmos, .terraV1, .terraV2, .sei:
            return CosmosTransactionParams(memo: extraDestinationId)

        case .algorand:
            return AlgorandTransactionParams(nonce: extraDestinationId)

        case .hedera:
            return HederaTransactionParams(memo: extraDestinationId)

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
             .internetComputer,
             .cyber,
             .blast,
             .filecoin,
             .sui,
             .energyWebEVM,
             .energyWebX,
             .core:
            throw ExpressTransactionBuilderError.blockchainDonNotSupportedExtraId
        }
    }
}

enum ExpressTransactionBuilderError: LocalizedError {
    case approveImpossibleInNotEvmBlockchain
    case transactionDataForSwapOperationNotFound
    case blockchainDonNotSupportedExtraId
}
