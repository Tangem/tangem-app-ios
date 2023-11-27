//
//  CommonExpressTransactionBuilder.swift
//  Tangem
//
//  Created by Sergey Balashov on 21.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSwapping

struct CommonExpressTransactionBuilder: ExpressTransactionBuilder {
    func makeTransaction(wallet: WalletModel, data: ExpressTransactionData, fee: Fee) async throws -> BlockchainSdk.Transaction {
        let transaction = try await buildTransaction(
            wallet: wallet,
            amount: data.value,
            fee: fee,
            sourceAddress: data.sourceAddress ?? wallet.defaultAddress,
            destinationAddress: data.destinationAddress,
            data: data.txData.map { Data(hexString: $0) }
        )

        return transaction
    }

    func makeApproveTransaction(wallet: WalletModel, data: Data, fee: Fee, contractAddress: String) async throws -> Transaction {
        guard wallet.ethereumNetworkProvider != nil else {
            throw ExpressTransactionBuilderError.approveImpossibleInNotEvmBlockchain
        }

        let transaction = try await buildTransaction(
            wallet: wallet,
            amount: 0, // For approve value isn't needed
            fee: fee,
            sourceAddress: wallet.defaultAddress,
            destinationAddress: contractAddress,
            data: data
        )

        return transaction
    }
}

private extension CommonExpressTransactionBuilder {
    func buildTransaction(
        wallet: WalletModel,
        amount: Decimal,
        fee: Fee,
        sourceAddress: String?,
        destinationAddress: String,
        data: Data?
    ) async throws -> Transaction {
        let amount = Amount(with: wallet.tokenItem.blockchain, type: wallet.amountType, value: amount)
        let source = sourceAddress ?? wallet.defaultAddress
        var transaction = BlockchainSdk.Transaction(
            amount: amount,
            fee: fee,
            sourceAddress: source,
            destinationAddress: destinationAddress,
            changeAddress: source,
            contractAddress: destinationAddress
        )

        // In EVM-like blockchains we should add the txData to the transaction
        if let data, let ethereumNetworkProvider = wallet.ethereumNetworkProvider {
            let nonce = try await ethereumNetworkProvider.getTxCount(source).async()
            transaction.params = EthereumTransactionParams(
                data: data,
                nonce: nonce
            )
        }

        return transaction
    }
}

enum ExpressTransactionBuilderError: LocalizedError {
    case approveImpossibleInNotEvmBlockchain
}
