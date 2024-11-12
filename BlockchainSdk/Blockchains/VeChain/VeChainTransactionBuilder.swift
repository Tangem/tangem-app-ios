//
//  VeChainTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 18.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import WalletCore
import BigInt
import TangemFoundation

final class VeChainTransactionBuilder {
    private let isTestnet: Bool

    private var coinType: CoinType { .veChain }

    /// The last byte of the genesis block ID which is used to identify a blockchain to prevent the cross-chain replay attack.
    /// Mainnet: https://explore.vechain.org/blocks/0x00000000851caf3cfdb6e899cf5958bfb1ac3413d346d43539627e6be7ec1b4a
    /// Testnet: https://explore-testnet.vechain.org/blocks/0x000000000b2bce3c70bc649a02749e8687721b09ed2e15997f466536b20bb127
    private var chainTag: Int { isTestnet ? 0x27 : 0x4a }

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }

    func buildForSign(transaction: Transaction) throws -> Data {
        guard transaction.params is VeChainTransactionParams else {
            throw WalletError.failedToBuildTx
        }

        let input = try buildInput(transaction: transaction)
        let txInputData = try input.serializedData()

        guard !txInputData.isEmpty else {
            throw WalletError.failedToBuildTx
        }

        let preImageHashes = TransactionCompiler.preImageHashes(coinType: coinType, txInputData: txInputData)
        let output = try TxCompilerPreSigningOutput(serializedData: preImageHashes)

        guard output.error == .ok else {
            throw WalletError.failedToBuildTx
        }

        return output.dataHash
    }

    func buildForSend(transaction: Transaction, hash: Data, signature: Data) throws -> Data {
        guard let transactionParams = transaction.params as? VeChainTransactionParams else {
            throw WalletError.failedToBuildTx
        }

        let input = try buildInput(transaction: transaction)
        let txInputData = try input.serializedData()

        guard !txInputData.isEmpty else {
            throw WalletError.failedToBuildTx
        }

        let publicKey = try Secp256k1Key(with: transactionParams.publicKey.blockchainKey).decompress()
        let unmarshalledSignature = try SignatureUtils.unmarshalledSignature(
            from: signature,
            publicKey: publicKey,
            hash: hash
        )

        let compiledTransaction = TransactionCompiler.compileWithSignatures(
            coinType: coinType,
            txInputData: txInputData,
            signatures: unmarshalledSignature.asDataVector(),
            publicKeys: publicKey.asDataVector()
        )

        let output = try VeChainSigningOutput(serializedData: compiledTransaction)

        guard output.error == .ok else {
            throw WalletError.failedToBuildTx
        }

        let serializedData = output.encoded

        guard !serializedData.isEmpty else {
            throw WalletError.failedToBuildTx
        }

        return serializedData
    }

    func buildInputForFeeCalculation(transaction: Transaction) throws -> VeChainFeeCalculator.Input {
        let input = try buildInput(transaction: transaction)

        return VeChainFeeCalculator.Input(
            gasPriceCoefficient: UInt(input.gasPriceCoef),
            clauses: input.clauses.map(\.asFeeCalculationInput)
        )
    }

    private func buildInput(transaction: Transaction) throws -> VeChainSigningInput {
        guard let transactionParams = transaction.params as? VeChainTransactionParams else {
            throw WalletError.failedToBuildTx
        }

        let feeCalculator = VeChainFeeCalculator(isTestnet: isTestnet)

        let clauses = try buildClauses(transaction: transaction)
        var gas = feeCalculator.gas(for: clauses.map(\.asFeeCalculationInput))

        var gasPriceCoefficient: UInt32 = 0
        if let feeParameters = transaction.fee.parameters as? VeChainFeeParams {
            gasPriceCoefficient = UInt32(feeCalculator.gasPriceCoefficient(from: feeParameters.priority))
            gas += feeParameters.vmGas
        }

        return VeChainSigningInput.with { input in
            input.chainTag = UInt32(chainTag)
            input.nonce = UInt64(transactionParams.nonce)
            input.blockRef = UInt64(transactionParams.lastBlockInfo.blockRef)
            input.expiration = UInt32(Constants.transactionExpiration)
            input.gasPriceCoef = gasPriceCoefficient
            input.gas = UInt64(gas)
            input.clauses = clauses
        }
    }

    private func buildClauses(transaction: Transaction) throws -> [VeChainClause] {
        let value = try transferValue(from: transaction)
        let destinationAddress = transaction.destinationAddress
        let clause = try VeChainClause.with { input in
            switch transaction.amount.type {
            case .coin:
                input.value = value.serialize()
                input.to = destinationAddress
                input.data = Data()
            case .token(let token):
                let tokenMethod = TransferERC20TokenMethod(destination: destinationAddress, amount: value)
                input.value = Data(0x00)
                input.to = token.contractAddress
                input.data = tokenMethod.data
            case .reserve, .feeResource:
                // Not supported
                throw WalletError.failedToBuildTx
            }
        }

        return [clause]
    }

    private func transferValue(from transaction: Transaction) throws -> BigUInt {
        let amount = transaction.amount
        let decimalValue = amount.value * pow(Decimal(10), amount.decimals)
        let roundedValue = decimalValue.rounded(roundingMode: .down)

        guard let bigUIntValue = BigUInt(decimal: roundedValue) else {
            throw WalletError.failedToBuildTx
        }

        return bigUIntValue
    }
}

// MARK: - Convenience extensions

private extension VeChainClause {
    var asFeeCalculationInput: VeChainFeeCalculator.Clause {
        return VeChainFeeCalculator.Clause(payload: data)
    }
}

// MARK: - Constants

private extension VeChainTransactionBuilder {
    enum Constants {
        /// `18` is the value used by the official `VeWorld` wallet app, multiplying it by 10 just in case.
        static let transactionExpiration = 18 * 10
    }
}
