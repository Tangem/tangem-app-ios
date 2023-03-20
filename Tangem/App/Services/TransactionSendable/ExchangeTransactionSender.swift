//
//  ExchangeTransactionSender.swift
//  Tangem
//
//  Created by Sergey Balashov on 12.12.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemExchange
import BlockchainSdk

struct ExchangeTransactionSender {
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

// MARK: - TransactionSendable

extension ExchangeTransactionSender: TransactionSendable {
    func sendTransaction(_ info: ExchangeTransactionDataModel) async throws -> TransactionSendResult {
        let nonce = try await ethereumNetworkProvider.getTxCount(info.sourceAddress).async()
        let transaction = try buildTransaction(for: info, nonce: nonce)
        return try await transactionSender.send(transaction, signer: transactionSigner).async()
    }
}

// MARK: - Private

private extension ExchangeTransactionSender {
    func buildTransaction(for info: ExchangeTransactionDataModel, nonce: Int) throws -> Transaction {
        let gasModel = info.gas

        let amount = createAmount(from: info.sourceCurrency, amount: info.value)
        let fee = try createAmount(from: info.sourceBlockchain, amount: gasModel.fee)

        var transaction = Transaction(
            amount: amount,
            fee: fee,
            sourceAddress: info.sourceAddress,
            destinationAddress: info.destinationAddress,
            changeAddress: info.sourceAddress,
            contractAddress: info.destinationAddress,
            date: Date(),
            status: .unconfirmed
        )

        transaction.params = EthereumTransactionParams(data: info.txData, gasLimit: gasModel.gasLimit, nonce: nonce)
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

    func createAmount(from exchangeBlockchain: ExchangeBlockchain, amount: Decimal) throws -> Amount {
        guard let blockchain = Blockchain(from: exchangeBlockchain.networkId) else {
            throw CommonError.noData
        }

        return Amount(with: blockchain, value: amount)
    }
}
