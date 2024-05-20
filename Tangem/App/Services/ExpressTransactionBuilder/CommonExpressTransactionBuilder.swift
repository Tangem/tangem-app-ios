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
        let destination: Destination = try {
            switch data.transactionType {
            case .send:
                return .send(data.destinationAddress)
            case .swap:
                if let txData = data.txData {
                    return .contractCall(data.destinationAddress, data: Data(hexString: txData))
                }

                throw ExpressTransactionBuilderError.transactionDataForSwapOperationNotFound
            }
        }()

        var transaction = try await buildTransaction(
            wallet: wallet,
            amount: data.value,
            fee: fee,
            sourceAddress: data.sourceAddress,
            destination: destination
        )

        if let extraDestinationId = data.extraDestinationId, !extraDestinationId.isEmpty {
            // If we received a extraId then try to map it to specific TransactionParams
            transaction.params = try mapToTransactionParams(blockchain: wallet.tokenItem.blockchain, extraDestinationId: extraDestinationId)
        }

        return transaction
    }

    func makeApproveTransaction(wallet: WalletModel, data: ExpressApproveData, fee: Fee) async throws -> BlockchainSdk.Transaction {
        guard wallet.ethereumNetworkProvider != nil else {
            throw ExpressTransactionBuilderError.approveImpossibleInNotEvmBlockchain
        }

        let transaction = try await buildTransaction(
            wallet: wallet,
            amount: 0, // For approve value isn't needed
            fee: fee,
            destination: .contractCall(data.toContractAddress, data: data.data)
        )

        return transaction
    }
}

private extension CommonExpressTransactionBuilder {
    func buildTransaction(
        wallet: WalletModel,
        amount: Decimal,
        fee: Fee,
        sourceAddress: String? = nil,
        destination: Destination
    ) async throws -> Transaction {
        let amount = Amount(with: wallet.tokenItem.blockchain, type: wallet.amountType, value: amount)
        let source = sourceAddress ?? wallet.defaultAddress

        switch destination {
        case .send(let string):
            return try await wallet.transactionCreator.createTransaction(amount: amount, fee: fee, destinationAddress: string)
        case .contractCall(let contract, let data):
            var transaction = BlockchainSdk.Transaction(
                amount: amount,
                fee: fee,
                sourceAddress: source,
                destinationAddress: contract,
                changeAddress: source,
                contractAddress: contract
            )

            // In EVM-like blockchains we should add the txData to the transaction
            if let ethereumNetworkProvider = wallet.ethereumNetworkProvider {
                let nonce = try await ethereumNetworkProvider.getTxCount(source).async()
                transaction.params = EthereumTransactionParams(
                    data: data,
                    nonce: nonce
                )
            }

            return transaction
        }
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

        case .cosmos, .terraV1, .terraV2:
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
             .joystream:
            throw ExpressTransactionBuilderError.blockchainDonNotSupportedExtraId
        }
    }

    enum Destination {
        case send(String)
        case contractCall(String, data: Data)
    }
}

enum ExpressTransactionBuilderError: LocalizedError {
    case approveImpossibleInNotEvmBlockchain
    case transactionDataForSwapOperationNotFound
    case blockchainDonNotSupportedExtraId
}
