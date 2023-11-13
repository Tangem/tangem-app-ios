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

    private func getGasPrice(for tx: WalletConnectEthTransaction, using gasLoader: EthereumGasLoader) async throws -> Int {
        if let gasPrice = tx.gasPrice?.hexToInteger {
            return gasPrice
        }

        let price = try await gasLoader.getGasPrice().async()
        return Int(price)
    }

    private func getGasLimit(for tx: WalletConnectEthTransaction, with amount: Amount, using gasLoader: EthereumGasLoader) async throws -> Int {
        if let dappGasLimit = tx.gas?.hexToInteger ?? tx.gasLimit?.hexToInteger {
            return dappGasLimit
        }

        // If amount is zero it is better to use default zero string `0x0`, because some dApps (app.thorswap.finance) can send
        // weird values such as `0x00`, `0x00000` and JSON-RPC node won't be able to handle this info
        // and will return an error. `EthereumUtils` can correctly parse weird values, but it is still better
        // to send value from dApp instead of creating it yourself. IOS-4865
        let valueString = amount.value.isZero ? zeroString : tx.value

        let gasLimitBigInt = try await gasLoader.getGasLimit(
            to: tx.to,
            from: tx.from,
            value: valueString,
            data: tx.data
        ).async()
        return Int(gasLimitBigInt)
    }
}

extension CommonWalletConnectEthTransactionBuilder: WalletConnectEthTransactionBuilder {
    func buildTx(from wcTransaction: WalletConnectEthTransaction, for walletModel: WalletModel) async throws -> Transaction {
        guard let gasLoader = walletModel.ethereumGasLoader else {
            let error = WalletConnectV2Error.missingGasLoader
            AppLog.shared.error(error)
            throw error
        }

        let blockchain = walletModel.wallet.blockchain
        let rawValue = wcTransaction.value ?? zeroString
        guard let value = EthereumUtils.parseEthereumDecimal(rawValue, decimalsCount: blockchain.decimalCount) else {
            let error = ETHError.failedToParseBalance(value: rawValue, address: "", decimals: blockchain.decimalCount)
            AppLog.shared.error(error)
            throw error
        }

        let valueAmount = Amount(with: blockchain, type: .coin, value: value)

        async let walletUpdate = walletModel.update(silent: false).async()
        async let gasPrice = getGasPrice(for: wcTransaction, using: gasLoader)
        async let gasLimit = getGasLimit(for: wcTransaction, with: valueAmount, using: gasLoader)

        let feeValue = try await Decimal(gasLimit * gasPrice) / blockchain.decimalValue
        let gasAmount = Amount(with: blockchain, value: feeValue)
        let feeParameters = try await EthereumFeeParameters(gasLimit: BigUInt(gasLimit), gasPrice: BigUInt(gasPrice))
        let fee = Fee(gasAmount, parameters: feeParameters)
        let _ = await walletUpdate

        var transaction = try walletModel.transactionCreator.createTransaction(
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
