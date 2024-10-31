//
//  AptosTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 25.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
import TangemSdk

final class AptosTransactionBuilder {
    private let publicKey: Data
    private let walletAddress: String
    private let decimalValue: Decimal
    private let chainId: AptosChainId

    private var coinType: CoinType { .aptos }
    private var sequenceNumber: Int64 = 0

    var currentSequenceNumber: Int64 {
        sequenceNumber
    }

    // MARK: - Init

    init(
        publicKey: Data,
        decimalValue: Decimal,
        walletAddress: String,
        chainId: AptosChainId
    ) {
        self.publicKey = publicKey
        self.decimalValue = decimalValue
        self.walletAddress = walletAddress
        self.chainId = chainId
    }

    // MARK: - Implementation

    func update(sequenceNumber: Int64) {
        self.sequenceNumber = sequenceNumber
    }

    func buildForSign(transaction: Transaction, expirationTimestamp: UInt64) throws -> Data {
        let input = try buildInput(transaction: transaction, expirationTimestamp: expirationTimestamp)
        let txInputData = try input.serializedData()

        guard !txInputData.isEmpty else {
            throw WalletError.failedToBuildTx
        }

        let preImageHashes = TransactionCompiler.preImageHashes(coinType: coinType, txInputData: txInputData)
        let preSigningOutput = try TxCompilerPreSigningOutput(serializedData: preImageHashes)

        guard preSigningOutput.error == .ok, !preSigningOutput.data.isEmpty else {
            Log.debug("AptosPreSigningOutput has a error: \(preSigningOutput.errorMessage)")
            throw WalletError.failedToBuildTx
        }

        return preSigningOutput.data
    }

    func buildForSend(transaction: Transaction, signature: Data, expirationTimestamp: UInt64) throws -> Data {
        let input = try buildInput(transaction: transaction, expirationTimestamp: expirationTimestamp)
        let txInputData = try input.serializedData()

        guard !txInputData.isEmpty else {
            throw WalletError.failedToBuildTx
        }

        let compiledTransaction = TransactionCompiler.compileWithSignatures(
            coinType: coinType,
            txInputData: txInputData,
            signatures: signature.asDataVector(),
            publicKeys: publicKey.asDataVector()
        )

        let signingOutput = try AptosSigningOutput(serializedData: compiledTransaction)

        guard signingOutput.error == .ok, signingOutput.hasAuthenticator else {
            Log.debug("AptosSigningOutput has a error")
            throw WalletError.failedToBuildTx
        }

        guard let convertJsonData = signingOutput.json.data(using: .utf8) else {
            throw WalletError.failedToBuildTx
        }

        return convertJsonData
    }

    func buildToCalculateFee(
        amount: Amount,
        destination: String,
        gasUnitPrice: UInt64,
        expirationTimestamp: UInt64
    ) throws -> AptosTransactionInfo {
        AptosTransactionInfo(
            sequenceNumber: sequenceNumber,
            publicKey: publicKey.hexString,
            sourceAddress: walletAddress,
            destinationAddress: destination,
            amount: (amount.value * decimalValue).roundedDecimalNumber.uint64Value,
            contractAddress: amount.type.token?.contractAddress,
            gasUnitPrice: gasUnitPrice,
            maxGasAmount: Constants.pseudoTransactionMaxGasAmount,
            expirationTimestamp: expirationTimestamp,
            hash: Constants.pseudoTransactionHash
        )
    }

    // MARK: - Private Implementation

    /*
     This links describe basic structure transaction Aptos Blockchain
     - https://aptos.dev/concepts/txns-states
     */
    private func buildInput(transaction: Transaction, expirationTimestamp: UInt64) throws -> AptosSigningInput {
        try publicKey.validateAsEdKey()

        let sequenceNumber = sequenceNumber
        let chainID = chainId.rawValue
        let amount = (transaction.amount.value * decimalValue).roundedDecimalNumber.uint64Value
        let gasUnitPrice = (transaction.fee.parameters as? AptosFeeParams)?.gasUnitPrice ?? 0
        let maxGasAmount = (transaction.fee.parameters as? AptosFeeParams)?.maxGasAmount ?? 0

        let transfer = AptosTransferMessage.with {
            $0.to = transaction.destinationAddress
            $0.amount = amount
        }

        let input = AptosSigningInput.with { input in
            input.chainID = chainID
            input.sender = transaction.sourceAddress
            input.sequenceNumber = sequenceNumber
            input.expirationTimestampSecs = expirationTimestamp
            input.gasUnitPrice = gasUnitPrice
            input.transfer = transfer
            input.gasUnitPrice = gasUnitPrice
            input.maxGasAmount = maxGasAmount
            input.expirationTimestampSecs = expirationTimestamp
        }

        return input
    }
}

extension AptosTransactionBuilder {
    /*
     - For chainId documentation link https://aptos.dev/nodes/networks/
     */
    enum Constants {
        static let pseudoTransactionMaxGasAmount: UInt64 = 100_000
        static let pseudoTransactionHash = "0x000000000000000000000000000000000000000000000000000000000000000000000" +
            "00000000000000000000000000000000000000000000000000000000000"
    }
}
