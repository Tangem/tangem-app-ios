//
//  PolkadotStakeKitTransactionHelper.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 16.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
import BigInt

struct PolkadotStakeKitTransactionHelper {
    private let transactionBuilder: PolkadotTransactionBuilder

    init(transactionBuilder: PolkadotTransactionBuilder) {
        self.transactionBuilder = transactionBuilder
    }

    func prepareForSign(_ stakingTransaction: StakeKitTransaction) throws -> Data {
        let input = try buildSigningInput(stakingTransaction: stakingTransaction)
        return try transactionBuilder.buildForSign(
            amount: stakingTransaction.amount,
            destination: input.address,
            call: input.call,
            meta: input.meta
        )
    }

    func prepareForSend(
        stakingTransaction: StakeKitTransaction,
        signatureInfo: SignatureInfo
    ) throws -> Data {
        let input = try buildSigningInput(stakingTransaction: stakingTransaction)
        return try transactionBuilder.buildForSend(
            amount: stakingTransaction.amount,
            destination: input.address,
            call: input.call,
            meta: input.meta,
            signature: signatureInfo.signature
        )
    }

    private func buildSigningInput(
        stakingTransaction: StakeKitTransaction
    ) throws -> SigningInput {
        guard let compiledTransactionData = stakingTransaction.unsignedData.data(using: .utf8) else {
            throw EthereumTransactionBuilderError.invalidStakingTransaction
        }

        let compiledTransaction = try JSONDecoder()
            .decode(CompiledTransaction.self, from: compiledTransactionData)
        guard let transactionVersion = UInt32(compiledTransaction.tx.transactionVersion.removeHexPrefix(), radix: 16),
              let nonce = UInt64(compiledTransaction.tx.nonce.removeHexPrefix(), radix: 16),
              let blockNumber = UInt64(compiledTransaction.tx.blockNumber.removeHexPrefix(), radix: 16),
              let era = UInt64(compiledTransaction.tx.era.removeHexPrefix(), radix: 16) else {
            throw EthereumTransactionBuilderError.invalidStakingTransaction
        }

        let meta = PolkadotBlockchainMeta(
            specVersion: compiledTransaction.specVersion,
            transactionVersion: transactionVersion,
            genesisHash: compiledTransaction.tx.genesisHash,
            blockHash: compiledTransaction.tx.blockHash,
            nonce: nonce,
            era: .init(
                blockNumber: blockNumber,
                period: 128
            )
        )
        return SigningInput(
            meta: meta,
            address: compiledTransaction.tx.address,
            call: Data(hex: compiledTransaction.tx.method)
        )
    }
}

private extension PolkadotStakeKitTransactionHelper {
    struct CompiledTransaction: Decodable {
        let specName: String
        let tx: Tx
        let specVersion: UInt32

        struct Tx: Decodable {
            let version: Int
            let nonce: String
            let blockHash: String
            let genesisHash: String
            let signedExtensions: [String]
            let specVersion: String
            let address: String
            let tip: String
            let metadataRpc: String
            let blockNumber: String
            let era: String
            let transactionVersion: String
            let method: String
        }
    }

    struct SigningInput {
        let meta: PolkadotBlockchainMeta
        let address: String
        let call: Data
    }
}
