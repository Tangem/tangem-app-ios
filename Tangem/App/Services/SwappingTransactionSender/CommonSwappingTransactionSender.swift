//
//  CommonSwappingTransactionSender.swift
//  Tangem
//
//  Created by Sergey Balashov on 12.12.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemSwapping
import BlockchainSdk
import BigInt

struct CommonSwappingTransactionSender {
    private let transactionCreator: TransactionCreator
    private let transactionSender: TransactionSender
    private let transactionSigner: TransactionSigner
    private let ethereumNetworkProvider: EthereumNetworkProvider
    private let currencyMapper: CurrencyMapping

    init(
        transactionCreator: TransactionCreator,
        transactionSender: TransactionSender,
        transactionSigner: TransactionSigner,
        ethereumNetworkProvider: EthereumNetworkProvider,
        currencyMapper: CurrencyMapping
    ) {
        self.transactionCreator = transactionCreator
        self.transactionSender = transactionSender
        self.transactionSigner = transactionSigner
        self.ethereumNetworkProvider = ethereumNetworkProvider
        self.currencyMapper = currencyMapper
    }
}

// MARK: - SwappingTransactionSender

extension CommonSwappingTransactionSender: SwappingTransactionSender {
    func sendTransaction(_ data: SwappingTransactionData) async throws -> TransactionSendResult {
        let nonce = try await ethereumNetworkProvider.getTxCount(data.sourceAddress).async()
        let transaction = try buildTransaction(for: data, nonce: nonce)
        return try await transactionSender.send(transaction, signer: transactionSigner).async()
    }
}

// MARK: - Private

private extension CommonSwappingTransactionSender {
    func buildTransaction(for data: SwappingTransactionData, nonce: Int) throws -> Transaction {
        let gasModel = data.gas

        let amount = createAmount(from: data.sourceCurrency, amount: data.value)
        let feeAmount = try createAmount(from: data.sourceBlockchain, amount: gasModel.fee)
        let feeParameters = EthereumFeeParameters(gasLimit: BigUInt(gasModel.gasLimit), gasPrice: BigUInt(gasModel.gasPrice))
        let fee = Fee(feeAmount, parameters: feeParameters)

        var transaction = Transaction(
            amount: amount,
            fee: fee,
            sourceAddress: data.sourceAddress,
            destinationAddress: data.destinationAddress,
            changeAddress: data.sourceAddress,
            contractAddress: data.destinationAddress,
            date: Date(),
            status: .unconfirmed
        )

        transaction.params = EthereumTransactionParams(
            data: data.txData,
            nonce: nonce
        )

        return transaction
    }

    func createAmount(from currency: Currency, amount: Decimal) -> Amount {
        if let token = currencyMapper.mapToToken(currency: currency) {
            return Amount(with: token, value: amount)
        }

        return Amount(
            type: .coin,
            currencySymbol: currency.symbol,
            value: amount,
            decimals: currency.decimalCount
        )
    }

    func createAmount(from swappingBlockchain: SwappingBlockchain, amount: Decimal) throws -> Amount {
        Amount(
            type: .coin,
            currencySymbol: swappingBlockchain.symbol,
            value: amount,
            decimals: swappingBlockchain.decimalCount
        )
    }
}
