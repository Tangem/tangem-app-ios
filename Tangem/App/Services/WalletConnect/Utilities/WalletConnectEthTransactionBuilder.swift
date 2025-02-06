//
//  CommonWalletConnectEthTransactionBuilder.swift
//  Tangem
//
//  Created by Andrew Son on 01/02/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import BigInt

protocol WalletConnectEthTransactionBuilder {
    func buildTx(from transaction: WalletConnectEthTransaction, for walletModel: WalletModel) async throws -> Transaction
}

struct CommonWalletConnectEthTransactionBuilder {
    private let zeroString = "0x0"

    private func getGasLimit(
        for tx: WalletConnectEthTransaction,
        with amount: Amount,
        using ethereumNetworkProvider: EthereumNetworkProvider,
        blockchain: Blockchain
    ) async throws -> BigUInt {
        if let dappGasLimit = tx.gas?.hexToInteger ?? tx.gasLimit?.hexToInteger {
            // This is a workaround for sending a Mantle transaction.
            // Unfortunately, Mantle's current implementation does not conform to our existing fee calculation rules.
            // https://tangem.slack.com/archives/GMXC6PP71/p1719591856597299?thread_ts=1714215815.690169&cid=GMXC6PP71
            if case .mantle = blockchain {
                return MantleUtils.multiplyGasLimit(dappGasLimit, with: MantleUtils.feeGasLimitMultiplier)
            }
            return BigUInt(dappGasLimit)
        }

        // If amount is zero it is better to use default zero string `0x0`, because some dApps (app.thorswap.finance) can send
        // weird values such as `0x00`, `0x00000` and JSON-RPC node won't be able to handle this info
        // and will return an error. `EthereumUtils` can correctly parse weird values, but it is still better
        // to send value from dApp instead of creating it yourself. IOS-4865
        let valueString = amount.value.isZero ? zeroString : tx.value

        let gasLimitBigInt = try await ethereumNetworkProvider.getGasLimit(
            to: tx.to,
            from: tx.from,
            value: valueString,
            data: tx.data
        ).async()
        return gasLimitBigInt
    }

    private func getFee(
        for tx: WalletConnectEthTransaction,
        with amount: Amount,
        blockchain: Blockchain,
        using ethereumNetworkProvider: EthereumNetworkProvider
    ) async throws -> Fee {
        async let gasLimit = getGasLimit(
            for: tx,
            with: amount,
            using: ethereumNetworkProvider,
            blockchain: blockchain
        )

        let gasPrice = tx.gasPrice?.hexToInteger.map { BigUInt($0) }
        let feeParameters = try await ethereumNetworkProvider.getFee(gasLimit: gasLimit, supportsEIP1559: blockchain.supportsEIP1559, gasPrice: gasPrice)
        let feeValue = feeParameters.calculateFee(decimalValue: blockchain.decimalValue)
        let gasAmount = Amount(with: blockchain, value: feeValue)

        let fee = Fee(gasAmount, parameters: feeParameters)
        return fee
    }
}

extension CommonWalletConnectEthTransactionBuilder: WalletConnectEthTransactionBuilder {
    func buildTx(from wcTransaction: WalletConnectEthTransaction, for walletModel: WalletModel) async throws -> Transaction {
        guard let ethereumNetworkProvider = walletModel.ethereumNetworkProvider else {
            let error = WalletConnectV2Error.missingGasLoader
            WCLogger.error(error: error)
            throw error
        }

        let blockchain = walletModel.wallet.blockchain
        let rawValue = wcTransaction.value ?? zeroString
        guard let value = EthereumUtils.parseEthereumDecimal(rawValue, decimalsCount: blockchain.decimalCount) else {
            let error = ETHError.failedToParseBalance(value: rawValue, address: "", decimals: blockchain.decimalCount)
            WCLogger.error(error: error)
            throw error
        }

        let valueAmount = Amount(with: blockchain, type: .coin, value: value)
        async let walletUpdate = walletModel.update(silent: false).async()
        let fee = try await getFee(for: wcTransaction, with: valueAmount, blockchain: blockchain, using: ethereumNetworkProvider)
        let _ = try await walletUpdate

        var transaction = try await walletModel.transactionCreator.createTransaction(
            amount: valueAmount,
            fee: fee,
            sourceAddress: wcTransaction.from,
            destinationAddress: wcTransaction.to
        )

        let contractDataString = wcTransaction.data.removeHexPrefix()
        let wcTxData = Data(hexString: String(contractDataString))

        transaction.params = EthereumTransactionParams(
            data: wcTxData,
            nonce: wcTransaction.nonce?.hexToInteger
        )

        return transaction
    }
}
