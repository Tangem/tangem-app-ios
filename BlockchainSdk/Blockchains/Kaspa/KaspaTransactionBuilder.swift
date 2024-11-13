//
//  KaspaTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 15.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
import TangemFoundation

class KaspaTransactionBuilder {
    let maxInputCount = 84

    private let blockchain: Blockchain
    private let walletPublicKey: Wallet.PublicKey
    private var unspentOutputs: [BitcoinUnspentOutput] = []
    private let addressService: KaspaAddressService

    init(walletPublicKey: Wallet.PublicKey, blockchain: Blockchain) {
        self.blockchain = blockchain
        self.walletPublicKey = walletPublicKey
        addressService = KaspaAddressService(isTestnet: blockchain.isTestnet)
    }

    func availableAmount() -> Amount {
        let inputs = unspentOutputs
        let availableAmountInSatoshi = inputs.reduce(0) { $0 + $1.amount }
        return Amount(with: blockchain, value: Decimal(availableAmountInSatoshi) / blockchain.decimalValue)
    }

    func unspentOutputsCount(for amount: Amount) -> Int {
        return unspentOutputs.count
    }

    func setUnspentOutputs(_ unspentOutputs: [BitcoinUnspentOutput]) {
        let sortedOutputs = unspentOutputs.sorted {
            $0.amount > $1.amount
        }

        self.unspentOutputs = Array(sortedOutputs.prefix(maxInputCount))
    }

    func buildForSign(_ transaction: Transaction) throws -> (KaspaTransaction, [Data]) {
        switch transaction.amount.type {
        case .token(let token):
            let commitTx = try buildCommitTransactionKRC20(transaction: transaction, token: token)
            return (commitTx.transaction, commitTx.hashes)
        default:
            ()
        }

        let availableInputValue = availableAmount()

        guard transaction.amount.type == availableInputValue.type,
              transaction.amount <= availableInputValue else {
            throw WalletError.failedToBuildTx
        }

        let destinationAddressScript = try scriptPublicKey(address: transaction.destinationAddress).hexString.lowercased()

        var outputs: [KaspaOutput] = [
            KaspaOutput(
                amount: amount(from: transaction),
                scriptPublicKey: KaspaScriptPublicKey(scriptPublicKey: destinationAddressScript)
            ),
        ]

        if let change = try change(transaction, unspentOutputs: unspentOutputs) {
            let sourceAddressScript = try scriptPublicKey(address: transaction.sourceAddress).hexString.lowercased()

            outputs.append(
                KaspaOutput(
                    amount: change,
                    scriptPublicKey: KaspaScriptPublicKey(scriptPublicKey: sourceAddressScript)
                )
            )
        }

        let kaspaTransaction = KaspaTransaction(inputs: unspentOutputs, outputs: outputs)

        let hashes = unspentOutputs.enumerated().map { index, unspentOutput in
            let value = unspentOutput.amount
            return kaspaTransaction.hashForSignatureWitness(
                inputIndex: index,
                connectedScript: Data(hexString: unspentOutput.outputScript),
                prevValue: value
            )
        }

        return (kaspaTransaction, hashes)
    }

    func buildForSend(transaction builtTransaction: KaspaTransaction, signatures: [Data]) -> KaspaTransactionData {
        let inputs = builtTransaction.inputs.enumerated().map { index, input in
            let sigHashAll: UInt8 = 1
            let script = signatures[index] + sigHashAll.data
            let size = UInt8(script.count)

            let signatureScript = (size.data + script).hexadecimal
            let outpoint = KaspaPreviousOutpoint(transactionId: input.transactionHash, index: input.outputIndex)
            return KaspaInput(previousOutpoint: outpoint, signatureScript: signatureScript)
        }

        return KaspaTransactionData(inputs: inputs, outputs: builtTransaction.outputs)
    }

    func buildForSendReveal(transaction builtTransaction: KaspaTransaction, commitRedeemScript: KaspaKRC20.RedeemScript, signatures: [Data]) -> KaspaTransactionData {
        let inputs = builtTransaction.inputs.enumerated().map { index, input in
            let sigHashAll: UInt8 = 1
            let script = signatures[index] + sigHashAll.data
            let size = UInt8(script.count)

            let outpoint = KaspaPreviousOutpoint(transactionId: input.transactionHash, index: input.outputIndex)

            switch index {
            case 0:
                let commitRedeemScriptData = commitRedeemScript.data
                let commitRedeemScriptDataCount = commitRedeemScriptData.count
                var commitRedeemScriptOpCodeData: Data

                switch commitRedeemScriptDataCount {
                case 0 ... 255:
                    commitRedeemScriptOpCodeData = OpCode.OP_PUSHDATA1.value.data + UInt8(commitRedeemScriptDataCount & 0xff).data
                case 255 ... 65535:
                    commitRedeemScriptOpCodeData = OpCode.OP_PUSHDATA2.value.data + UInt16(commitRedeemScriptDataCount & 0xffff).data
                default:
                    commitRedeemScriptOpCodeData = OpCode.OP_PUSHDATA4.value.data + UInt32(commitRedeemScriptDataCount & 0xffffffff).data
                }

                let signatureScript = (size.data + script + commitRedeemScriptOpCodeData + commitRedeemScript.data).hexadecimal
                return KaspaInput(previousOutpoint: outpoint, signatureScript: signatureScript)

            default:
                let signatureScript = (size.data + script).hexadecimal
                return KaspaInput(previousOutpoint: outpoint, signatureScript: signatureScript)
            }
        }

        return KaspaTransactionData(inputs: inputs, outputs: builtTransaction.outputs)
    }

    func buildForMassCalculation(transaction: Transaction) throws -> KaspaTransactionData {
        let amountValue = min(transaction.amount.value, availableAmount().value)
        let amount = Amount(with: blockchain, value: amountValue)

        let transaction = transaction.withAmount(amount)

        let builtTransaction = try buildForSign(transaction).0
        let dummySignature = Data(repeating: 1, count: 65)
        return buildForSend(
            transaction: builtTransaction,
            signatures: Array(
                repeating: dummySignature,
                count: builtTransaction.inputs.count
            )
        )
    }

    private func amount(from transaction: Transaction) -> UInt64 {
        return ((transaction.amount.value * blockchain.decimalValue) as NSDecimalNumber).uint64Value
    }

    private func change(_ transaction: Transaction, unspentOutputs: [BitcoinUnspentOutput]) throws -> UInt64? {
        let fullAmount = unspentOutputs.map { $0.amount }.reduce(0, +)
        let transactionAmount = ((transaction.amount.value * blockchain.decimalValue).rounded() as NSDecimalNumber).uint64Value
        let feeAmount = ((transaction.fee.amount.value * blockchain.decimalValue).rounded() as NSDecimalNumber).uint64Value

        let amountCharged = transactionAmount + feeAmount
        if fullAmount > amountCharged {
            return fullAmount - amountCharged
        } else if fullAmount == amountCharged {
            return nil
        } else {
            throw WalletError.failedToBuildTx
        }
    }

    private func scriptPublicKey(address: String) throws -> Data {
        guard let components = addressService.parse(address) else {
            throw WalletError.failedToBuildTx
        }

        let startOpCode: OpCode?
        let endOpCode: OpCode

        switch components.type {
        case .P2PK_Schnorr:
            startOpCode = nil
            endOpCode = OpCode.OP_CHECKSIG
        case .P2PK_ECDSA:
            startOpCode = nil
            endOpCode = OpCode.OP_CODESEPARATOR
        case .P2SH:
            startOpCode = OpCode.OP_HASH256
            endOpCode = OpCode.OP_EQUAL
        }

        let startOpCodeData: Data
        if let startOpCode {
            startOpCodeData = startOpCode.value.data
        } else {
            startOpCodeData = Data()
        }
        let endOpCodeData = endOpCode.value.data
        let size = UInt8(components.hash.count)

        return startOpCodeData + size.data + components.hash + endOpCodeData
    }
}

extension KaspaTransactionBuilder {
    func buildForMassCalculationKRC20(transaction: Transaction, token: Token) throws -> (commit: KaspaTransactionData, reveal: KaspaTransactionData) {
        let dummySignature = Data(repeating: 1, count: 65)
        let commitTx = try buildCommitTransactionKRC20(transaction: transaction, token: token, includeFee: false)
        let revealTx = try buildRevealTransaction(
            external: false,
            sourceAddress: transaction.sourceAddress,
            params: commitTx.params,
            fee: transaction.fee
        )

        return (
            commit:
            buildForSend(
                transaction: commitTx.transaction,
                signatures: Array(
                    repeating: dummySignature,
                    count: commitTx.transaction.inputs.count
                )
            ),
            reveal:
            buildForSendReveal(
                transaction: revealTx.transaction,
                commitRedeemScript: commitTx.redeemScript,
                signatures: Array(
                    repeating: dummySignature,
                    count: revealTx.transaction.inputs.count
                )
            )
        )
    }

    public func buildCommitTransactionKRC20(transaction: Transaction, token: Token, includeFee: Bool = true) throws -> KaspaKRC20.CommitTransction {
        let availableInputValue = availableAmount()

        guard transaction.fee.amount.type == availableInputValue.type,
              transaction.fee.amount <= availableInputValue else {
            throw WalletError.failedToBuildTx
        }

        guard let tokenDecimalValue = transaction.amount.type.token?.decimalValue else {
            throw WalletError.failedToBuildTx
        }

        var revealFeeParams: KaspaKRC20.RevealTransactionFeeParameter?

        if includeFee {
            guard let revealFee = transaction.fee.parameters as? KaspaKRC20.RevealTransactionFeeParameter else {
                throw WalletError.failedToBuildTx
            }
            revealFeeParams = revealFee
        }

        let feeEstimationRevealTransactionValue = ((revealFeeParams?.amount.value ?? 0) * blockchain.decimalValue).rounded()
        let dust = (Decimal(0.2) * blockchain.decimalValue).rounded()

        let tokenAmount = transaction.amount.value * tokenDecimalValue
        let sourceAddressScript = try scriptPublicKey(address: transaction.sourceAddress).hexString.lowercased()

        let envelope = KaspaKRC20.Envelope(
            amount: tokenAmount,
            recipient: transaction.destinationAddress,
            ticker: token.contractAddress
        )

        let redeemScript = KaspaKRC20.RedeemScript(publicKey: walletPublicKey.blockchainKey, envelope: envelope)
        let targetOutputAmount = dust.uint64Value + feeEstimationRevealTransactionValue.uint64Value

        var outputs = [
            KaspaOutput(
                amount: targetOutputAmount,
                scriptPublicKey: .init(scriptPublicKey: redeemScript.redeemScriptHash.hexadecimal)
            ),
        ]

        /*
         dust + estimated reveal transaction fee
         */
        if let change = try change(amount: dust + feeEstimationRevealTransactionValue, fee: (transaction.fee.amount.value * blockchain.decimalValue).rounded(), unspentOutputs: unspentOutputs) {
            outputs.append(
                KaspaOutput(
                    amount: change,
                    scriptPublicKey: KaspaScriptPublicKey(scriptPublicKey: sourceAddressScript)
                )
            )
        }

        let commitTransaction = KaspaTransaction(inputs: unspentOutputs, outputs: outputs)

        let commitHashes = unspentOutputs.enumerated().map { index, unspentOutput in
            let value = unspentOutput.amount
            return commitTransaction.hashForSignatureWitness(
                inputIndex: index,
                connectedScript: Data(hexString: unspentOutput.outputScript),
                prevValue: value
            )
        }

        guard let txid = commitTransaction.transactionId else {
            throw WalletError.failedToBuildTx
        }

        return KaspaKRC20.CommitTransction(
            transaction: commitTransaction,
            hashes: commitHashes,
            redeemScript: redeemScript,
            sourceAddress: transaction.sourceAddress,
            params: .init(
                transactionId: txid.hexadecimal,
                amount: targetOutputAmount,
                envelope: envelope
            )
        )
    }

    public func buildRevealTransaction(external: Bool, sourceAddress: String, params: KaspaKRC20.IncompleteTokenTransactionParams, fee: Fee) throws -> KaspaKRC20.RevealTransaction {
        let sourceAddressScript = try scriptPublicKey(address: sourceAddress).hexString.lowercased()
        let redeemScript = KaspaKRC20.RedeemScript(publicKey: walletPublicKey.blockchainKey, envelope: params.envelope)

        let commitTransactionOutput = [
            BitcoinUnspentOutput(transactionHash: params.transactionId, outputIndex: 0, amount: params.amount, outputScript: redeemScript.redeemScriptHash.hexadecimal),
        ]

        let utxo = external ? commitTransactionOutput + unspentOutputs : commitTransactionOutput

        let change = try change(amount: 0, fee: (fee.amount.value * blockchain.decimalValue).rounded(), unspentOutputs: utxo)!

        let outputs = [
            KaspaOutput(amount: change, scriptPublicKey: KaspaScriptPublicKey(scriptPublicKey: sourceAddressScript)),
        ]

        let transaction = KaspaTransaction(inputs: utxo, outputs: outputs)
        let hashes = utxo.enumerated().map { index, unspentOutput in
            let value = unspentOutput.amount
            return transaction.hashForSignatureWitness(
                inputIndex: index,
                connectedScript: Data(hexString: unspentOutput.outputScript),
                prevValue: value
            )
        }

        return KaspaKRC20.RevealTransaction(transaction: transaction, hashes: hashes, redeemScript: redeemScript)
    }

    private func change(amount: Decimal, fee: Decimal, unspentOutputs: [BitcoinUnspentOutput]) throws -> UInt64? {
        let fullAmount = unspentOutputs.map { $0.amount }.reduce(0, +)
        let transactionAmount = (amount as NSDecimalNumber).uint64Value
        let feeAmount = (fee as NSDecimalNumber).uint64Value

        let amountCharged = transactionAmount + feeAmount
        if fullAmount > amountCharged {
            return fullAmount - amountCharged
        } else if fullAmount == amountCharged {
            return nil
        } else {
            throw WalletError.failedToBuildTx
        }
    }
}
