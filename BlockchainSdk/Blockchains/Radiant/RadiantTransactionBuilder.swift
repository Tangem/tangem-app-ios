//
//  RadiantCashTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 14.02.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import WalletCore

class RadiantTransactionBuilder {
    private let walletPublicKey: Data
    private let decimalValue: Decimal

    private var utxo: [ElectrumUTXO] = []

    private let scriptUtils = RadiantScriptUtils()

    // MARK: - Init

    init(walletPublicKey: Data, decimalValue: Decimal) throws {
        self.walletPublicKey = try Secp256k1Key(with: walletPublicKey).compress()
        self.decimalValue = decimalValue
    }

    // MARK: - Implementation

    func update(utxo: [ElectrumUTXO]) {
        self.utxo = utxo
    }

    func buildForSign(transaction: Transaction) throws -> [Data] {
        let outputScript = scriptUtils.buildOutputScript(address: transaction.sourceAddress)
        let unspents = buildUnspents(with: [outputScript])

        let txForPreimage = RadiantAmountUnspentTransaction(
            decimalValue: decimalValue,
            amount: transaction.amount,
            fee: transaction.fee,
            unspents: unspents
        )

        let hashes = try unspents.enumerated().map { index, _ in
            let preImageHash = try buildPreImageHashe(
                with: txForPreimage,
                targetAddress: transaction.destinationAddress,
                sourceAddress: transaction.sourceAddress,
                index: index
            )

            return preImageHash.getDoubleSha256()
        }

        return hashes
    }

    func buildForSend(transaction: Transaction, signatures: [Data]) throws -> Data {
        let outputScripts = try scriptUtils.buildSignedScripts(
            signatures: signatures,
            publicKey: walletPublicKey,
            isDer: false
        )

        let unspents = buildUnspents(with: outputScripts)

        let txForSigned = RadiantAmountUnspentTransaction(
            decimalValue: decimalValue,
            amount: transaction.amount,
            fee: transaction.fee,
            unspents: unspents
        )

        let rawTransaction = try buildRawTransaction(
            with: txForSigned,
            targetAddress: transaction.destinationAddress,
            changeAddress: transaction.changeAddress,
            index: nil
        )

        return rawTransaction
    }

    func estimateTransactionSize(transaction: Transaction) throws -> Int {
        let hashesForSign = try buildForSign(transaction: transaction)
        let signaturesForSend = hashesForSign.map { _ in Data([UInt8](repeating: UInt8(0x01), count: 64)) }
        let rawTransaction = try buildForSend(transaction: transaction, signatures: signaturesForSend)

        return rawTransaction.count
    }

    // MARK: - Build Transaction Data

    /// Build preimage hashes for sign transaction with specify Radiant blockchain (etc. HashOutputHashes)
    /// - Parameters:
    ///   - tx: Union of unspents amount & change transaction
    ///   - targetAddress
    ///   - sourceAddress
    ///   - index: position image for output
    /// - Returns: Hash of one preimage
    private func buildPreImageHashe(
        with tx: RadiantAmountUnspentTransaction,
        targetAddress: String,
        sourceAddress: String,
        index: Int
    ) throws -> Data {
        var txToSign = Data()

        // version
        txToSign.append(contentsOf: [UInt8(0x01), UInt8(0x00), UInt8(0x00), UInt8(0x00)])

        // hashPrevouts
        scriptUtils.writePrevoutHash(tx.unspents, into: &txToSign)

        // hashSequence
        scriptUtils.writeSequenceHash(tx.unspents, into: &txToSign)

        // outpoint
        let currentOutput = tx.unspents[index]
        txToSign.append(contentsOf: currentOutput.hash.reversed())
        txToSign.append(contentsOf: currentOutput.outputIndex.bytes4LE)

        // scriptCode of the input (serialized as scripts inside CTxOuts)
        let scriptCode = scriptUtils.buildOutputScript(address: sourceAddress)

        txToSign.append(scriptCode.count.byte)
        txToSign.append(contentsOf: scriptCode)

        // value of the output spent by this input (8-byte little endian)
        txToSign.append(contentsOf: currentOutput.amount.bytes8LE)

        // nSequence of the input (4-byte little endian), ffffffff only
        txToSign.append(contentsOf: [UInt8(0xff), UInt8(0xff), UInt8(0xff), UInt8(0xff)])

        // hashOutputHashes (32-byte hash)
        try scriptUtils.writeHashOutputHashes(
            amount: tx.amountSatoshiDecimalValue,
            sourceAddress: sourceAddress,
            targetAddress: targetAddress,
            change: tx.changeSatoshiDecimalValue,
            into: &txToSign
        )

        // hashOutputs (32-byte hash)
        try scriptUtils.writeHashOutput(
            amount: tx.amountSatoshiDecimalValue,
            sourceAddress: sourceAddress,
            targetAddress: targetAddress,
            change: tx.changeSatoshiDecimalValue,
            into: &txToSign
        )

        // nLocktime of the transaction (4-byte little endian)
        txToSign.append(contentsOf: [UInt8(0x00), UInt8(0x00), UInt8(0x00), UInt8(0x00)])

        // sighash type of the signature (4-byte little endian)
        txToSign.append(contentsOf: [UInt8(0x41), UInt8(0x00), UInt8(0x00), UInt8(0x00)])

        return txToSign
    }

    /// Build raw transaction data without specify Radiant blockchain (etc. BitcoinCash)
    /// - Parameters:
    ///   - tx: Union of unspents amount & change transaction
    ///   - targetAddress
    ///   - changeAddress
    ///   - index: index of input transaction (specify nil value)
    /// - Returns: Raw transaction data
    private func buildRawTransaction(
        with tx: RadiantAmountUnspentTransaction,
        targetAddress: String,
        changeAddress: String,
        index: Int?
    ) throws -> Data {
        var txBody = Data()

        // version
        txBody.append(contentsOf: [UInt8(0x01), UInt8(0x00), UInt8(0x00), UInt8(0x00)])

        // 01
        txBody.append(tx.unspents.count.byte)

        // hex str hash prev btc
        for (inputIndex, input) in tx.unspents.enumerated() {
            let hashKey: [UInt8] = input.hash.reversed()
            txBody.append(contentsOf: hashKey)
            txBody.append(contentsOf: input.outputIndex.bytes4LE)

            if (index == nil) || (inputIndex == index) {
                txBody.append(input.outputScript.count.byte)
                txBody.append(contentsOf: input.outputScript)
            } else {
                txBody.append(UInt8(0x00))
            }

            // ffffffff
            txBody.append(contentsOf: [UInt8(0xff), UInt8(0xff), UInt8(0xff), UInt8(0xff)]) // sequence
        }

        // 02
        let outputCount = tx.changeSatoshiDecimalValue == 0 ? 1 : 2
        txBody.append(outputCount.byte)

        // 8 bytes
        txBody.append(contentsOf: tx.amountSatoshiDecimalValue.bytes8LE)

        let outputScriptBytes = scriptUtils.buildOutputScript(address: targetAddress)

        // hex str 1976a914....88ac
        txBody.append(outputScriptBytes.count.byte)
        txBody.append(contentsOf: outputScriptBytes)

        if tx.changeSatoshiDecimalValue != 0 {
            // 8 bytes of change satoshi value
            txBody.append(contentsOf: tx.changeSatoshiDecimalValue.bytes8LE)

            let outputScriptChangeBytes = scriptUtils.buildOutputScript(address: changeAddress)

            txBody.append(outputScriptChangeBytes.count.byte)
            txBody.append(contentsOf: outputScriptChangeBytes)
        }

        // 00000000
        txBody.append(contentsOf: [UInt8(0x00), UInt8(0x00), UInt8(0x00), UInt8(0x00)])

        return txBody
    }

    private func buildUnspents(with outputScripts: [Data]) -> [RadiantUnspentOutput] {
        utxo
            .enumerated()
            .compactMap { index, txRef in
                let hash = Data(hex: txRef.hash)
                let outputScript = outputScripts.count == 1 ? outputScripts.first! : outputScripts[index]
                return RadiantUnspentOutput(
                    amount: txRef.value.uint64Value,
                    outputIndex: txRef.position,
                    hash: hash,
                    outputScript: outputScript
                )
            }
    }
}
