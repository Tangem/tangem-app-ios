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

    private func getGasLimit(for tx: WalletConnectEthTransaction, with amount: Amount, using ethereumNetworkProvider: EthereumNetworkProvider) async throws -> BigUInt {
        if let dappGasLimit = tx.gas?.hexToInteger ?? tx.gasLimit?.hexToInteger {
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
}

extension CommonWalletConnectEthTransactionBuilder: WalletConnectEthTransactionBuilder {
    func buildTx(from wcTransaction: WalletConnectEthTransaction, for walletModel: WalletModel) async throws -> Transaction {
        guard let ethereumNetworkProvider = walletModel.ethereumNetworkProvider else {
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
        async let baseFee = ethereumNetworkProvider.getBaseFee().async()
        async let priorityFee = ethereumNetworkProvider.getPriorityFee().async()
        async let gasLimit = getGasLimit(for: wcTransaction, with: valueAmount, using: ethereumNetworkProvider)

        let feeParameters = try await EthereumEIP1559FeeParameters(gasLimit: gasLimit, baseFee: baseFee, priorityFee: priorityFee)
        let feeValue = feeParameters.caclulateFee(decimalValue: blockchain.decimalValue)
        let gasAmount = Amount(with: blockchain, value: feeValue)

        let fee = Fee(gasAmount, parameters: feeParameters)
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
