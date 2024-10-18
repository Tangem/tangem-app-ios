//
//  ICPTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 24.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
import IcpKit
import Combine

final class ICPTransactionBuilder {
    // MARK: - Private Properties

    private let decimalValue: Decimal
    private let publicKey: Data
    private let nonce: () throws -> Data

    // MARK: - Init

    init(decimalValue: Decimal, publicKey: Data, nonce: @autoclosure @escaping () throws -> Data) {
        self.decimalValue = decimalValue
        self.publicKey = publicKey
        self.nonce = nonce
    }

    // MARK: - Implementation

    /// Build input for sign transaction
    /// - Parameters:
    ///   - transaction: Transaction
    ///   - date: current timestamp
    /// - Returns: ICPSigningInput for sign transaction with external signer
    func buildForSign(
        transaction: Transaction,
        date: Date = Date()
    ) throws -> ICPSigningInput {
        guard let publicKey = PublicKey(
            tangemPublicKey: publicKey,
            publicKeyType: CoinType.internetComputer.publicKeyType
        ) else {
            throw WalletError.failedToBuildTx
        }

        return try ICPSigningInput(
            publicKey: publicKey.data,
            nonce: nonce,
            decimalValue: decimalValue,
            date: date,
            transaction: transaction
        )
    }

    /// Build for send transaction obtain external message output
    /// - Parameters:
    ///   - signedHashes: hashes from transaction signer
    ///   - input: result of buildForSign call
    /// - Returns: model containing signed envelopes ready for sending to API
    func buildForSend(signedHashes: [Data], input: ICPSigningInput) throws -> ICPSigningOutput {
        guard signedHashes.count == 2,
              let callSignature = signedHashes.first,
              let readStateSignature = signedHashes.last else {
            throw WalletError.empty
        }
        return try ICPSigningOutput(
            data: input.requestData,
            callSignature: callSignature,
            readStateSignature: readStateSignature
        )
    }

    /// Model for generation hashes to sign
    /// from transaction parameters
    struct ICPSigningInput {
        /// Wallet public key
        let publicKey: Data
        /// Domain separator string for request, e.g. 'ic-request'
        let domainSeparator: ICPDomainSeparator
        /// Aggregates data required for requests
        let requestData: ICPRequestsData

        /// Creates instance
        /// - Parameters:
        ///   - publicKey: public key data
        ///   - nonce: random 32-bytes length data provider
        ///   - decimalValue:
        ///   - date: current timestamp
        ///   - transaction: input transaction
        init(
            publicKey: Data,
            nonce: () throws -> Data,
            decimalValue: Decimal,
            date: Date,
            transaction: Transaction
        ) throws {
            self.publicKey = publicKey
            domainSeparator = ICPDomainSeparator(stringLiteral: "ic-request")

            let transactionParams = transaction.params as? ICPTransactionParams

            let icpTransactionParams = ICPTransaction.TransactionParams(
                destination: Data(hex: transaction.destinationAddress),
                amount: (transaction.amount.value * decimalValue).uint64Value,
                date: date,
                memo: transactionParams?.memo
            )

            requestData = try ICPSign.makeRequestData(
                publicKey: publicKey,
                nonce: nonce,
                transactionParams: icpTransactionParams
            )
        }

        /// Generates hashes for signing
        /// - Returns: hashes for signing
        func hashes() -> [Data] {
            requestData.hashes(for: domainSeparator)
        }
    }

    /// Aggregates signed envelopes data for sending
    struct ICPSigningOutput {
        let callEnvelope: Data
        let readStateEnvelope: Data
        let readStateTreePaths: [ICPStateTreePath]

        init(data: ICPRequestsData, callSignature: Data, readStateSignature: Data) throws {
            callEnvelope = try ICPRequestEnvelope(
                content: data.callRequestContent,
                senderPubkey: data.derEncodedPublicKey,
                senderSig: callSignature
            ).cborEncoded()
            readStateEnvelope = try ICPRequestEnvelope(
                content: data.readStateRequestContent,
                senderPubkey: data.derEncodedPublicKey,
                senderSig: readStateSignature
            ).cborEncoded()
            readStateTreePaths = data.readStateTreePaths
        }
    }
}
