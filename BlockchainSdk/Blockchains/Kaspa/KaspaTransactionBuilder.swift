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
    private var unspentOutputs: [BitcoinUnspentOutput] = []
    private let addressService: KaspaAddressService

    init(blockchain: Blockchain) {
        self.blockchain = blockchain
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
