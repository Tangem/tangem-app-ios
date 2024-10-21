//
//  EthereumStakeKitTransactionHelper.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 16.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
import BigInt

struct EthereumStakeKitTransactionHelper {
    private let transactionBuilder: EthereumTransactionBuilder

    init(transactionBuilder: EthereumTransactionBuilder) {
        self.transactionBuilder = transactionBuilder
    }

    func prepareForSign(_ stakingTransaction: StakeKitTransaction) throws -> Data {
        let input = try buildSigningInput(stakingTransaction: stakingTransaction)
        let preSigningOutput = try transactionBuilder.buildTxCompilerPreSigningOutput(input: input)
        return preSigningOutput.dataHash
    }

    func prepareForSend(
        stakingTransaction: StakeKitTransaction,
        signatureInfo: SignatureInfo
    ) throws -> Data {
        let input = try buildSigningInput(stakingTransaction: stakingTransaction)
        let output = try transactionBuilder.buildSigningOutput(input: input, signatureInfo: signatureInfo)
        return output.encoded
    }

    private func buildSigningInput(
        stakingTransaction: StakeKitTransaction
    ) throws -> EthereumSigningInput {
        guard let compiledTransactionData = stakingTransaction.unsignedData.data(using: .utf8) else {
            throw EthereumTransactionBuilderError.invalidStakingTransaction
        }

        let compiledTransaction = try JSONDecoder()
            .decode(EthereumCompiledTransaction.self, from: compiledTransactionData)

        let gasLimit = BigUInt(Data(hex: compiledTransaction.gasLimit))
        let baseFee = BigUInt(Data(hex: compiledTransaction.maxFeePerGas))
        let priorityFee = BigUInt(Data(hex: compiledTransaction.maxPriorityFeePerGas))

        guard gasLimit > 0, baseFee > 0, priorityFee > 0 else {
            throw EthereumTransactionBuilderError.feeParametersNotFound
        }

        let data = Data(hex: compiledTransaction.data)

        guard !data.isEmpty else {
            throw EthereumTransactionBuilderError.invalidStakingTransaction
        }

        return try transactionBuilder.buildSigningInput(
            destination: compiledTransaction.to,
            coinAmount: .zero,
            fee: Fee(
                stakingTransaction.fee.amount,
                parameters: EthereumEIP1559FeeParameters(gasLimit: gasLimit, baseFee: baseFee, priorityFee: priorityFee)
            ),
            nonce: compiledTransaction.nonce,
            data: data
        )
    }
}

fileprivate struct EthereumCompiledTransaction: Decodable {
    let from: String
    let gasLimit: String
    let to: String
    let data: String
    let nonce: Int
    let type: Int
    let maxFeePerGas: String
    let maxPriorityFeePerGas: String
    let chainId: Int
}
