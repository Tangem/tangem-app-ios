//
//  HederaTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 25.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Hedera
import CryptoSwift
import TangemSdk

final class HederaTransactionBuilder {
    private let publicKey: Data
    private let curve: EllipticCurve
    private let isTestnet: Bool

    private lazy var client: Client = isTestnet ? Client.forTestnet() : Client.forMainnet()

    init(publicKey: Data, curve: EllipticCurve, isTestnet: Bool) {
        self.publicKey = publicKey
        self.curve = curve
        self.isTestnet = isTestnet
    }

    func buildTokenAssociationForSign(
        tokenAssociation: TokenAssociation,
        validStartDate: UnixTimestamp,
        nodeAccountIds: [Int]?
    ) throws -> CompiledTransaction {
        let accountId = try AccountId.fromSolidityAddressOrString(tokenAssociation.accountId)
        let tokenId = try TokenId.fromSolidityAddressOrString(tokenAssociation.contractAddress)
        let transactionId = try makeTransactionId(accountId: accountId, validStartDate: validStartDate)

        let nodeAccountIds = nodeAccountIds?
            .map(UInt64.init)
            .map(AccountId.init(num:))

        // Fees for token association transactions are constant, therefore we don't adjust `maxTransactionFee` for the transaction
        let tokenAssociateTransaction = try TokenAssociateTransaction(accountId: accountId, tokenIds: [tokenId])
            .transactionId(transactionId)
            .nodeAccountIdsIfNotEmpty(nodeAccountIds)
            .freezeWith(client)

        return CompiledTransaction(curve: curve, client: client, innerTransaction: tokenAssociateTransaction)
    }

    /// Build transaction for signing.
    /// - parameter nodeAccountIds: A list of consensus network nodes for sending this transaction;
    /// Pass `nil` to let the Hedera SDK network layer select valid and alive consensus network nodes on its own.
    func buildTransferTransactionForSign(
        transaction: Transaction,
        validStartDate: UnixTimestamp,
        nodeAccountIds: [Int]?
    ) throws -> CompiledTransaction {
        // At the moment, we intentionally don't support custom fees for HTS tokens (HIP-18 https://hips.hedera.com/HIP/hip-18.html)
        let feeValue = transaction.fee.amount.value * pow(Decimal(10), transaction.fee.amount.decimals)
        // Hedera fee calculation involves conversion from USD to HBar units, which ultimately results in a loss of precision.
        // Therefore, the fee value is always approximate and rounding of the fee value is mandatory.
        let feeRoundedValue = feeValue.rounded(roundingMode: .up)
        let feeAmount = try Hbar(feeRoundedValue, .tinybar)

        let sourceAccountId = try AccountId.fromSolidityAddressOrString(transaction.sourceAddress)
        let destinationAccountId = try AccountId.fromSolidityAddressOrString(transaction.destinationAddress)

        let transactionId = try makeTransactionId(accountId: sourceAccountId, validStartDate: validStartDate)
        let transactionParams = transaction.params as? HederaTransactionParams

        let nodeAccountIds = nodeAccountIds?
            .map(UInt64.init)
            .map(AccountId.init(num:))

        let transferTransaction = try makeTransferTransaction(
            amount: transaction.amount,
            sourceAccountId: sourceAccountId,
            destinationAccountId: destinationAccountId
        )
        .transactionId(transactionId)
        .maxTransactionFee(feeAmount)
        .transactionMemo(transactionParams?.memo ?? "")
        .nodeAccountIdsIfNotEmpty(nodeAccountIds)
        .freezeWith(client)

        logTransferTransaction(transferTransaction)

        /// Capturing an existing `Hedera.Client` instance here is not required but may come in handy
        /// because the client may already have some useful internal state at this point
        /// (like the list of ready-to-use GRCP nodes with health checks already performed)
        return CompiledTransaction(curve: curve, client: client, innerTransaction: transferTransaction)
    }

    func buildForSend(transaction: CompiledTransaction, signatures: [Data]) throws -> CompiledTransaction {
        let publicKey = try getPublicKey()
        transaction.addSignatures(publicKey, signatures)

        return transaction
    }

    private func getPublicKey() throws -> Hedera.PublicKey {
        switch curve {
        case .ed25519, .ed25519_slip0010:
            return try .fromBytesEd25519(publicKey)
        case .secp256k1:
            let ecdsaKey = try Secp256k1Key(with: publicKey).compress()
            return try .fromBytesEcdsa(ecdsaKey)
        default:
            throw HederaError.unsupportedCurve(curveName: curve.rawValue)
        }
    }

    private func makeTransactionId(accountId: Hedera.AccountId, validStartDate: UnixTimestamp) throws -> Hedera.TransactionId {
        let (validStartDateNSec, multiplicationOverflow) = UInt64(validStartDate.seconds).multipliedReportingOverflow(by: NSEC_PER_SEC)
        if multiplicationOverflow {
            Log.debug("\(#fileID): Unable to create tx id due to multiplication overflow of '\(validStartDate)'")
            throw WalletError.failedToBuildTx
        }

        let (unixTimestampNSec, addingOverflow) = validStartDateNSec.addingReportingOverflow(UInt64(validStartDate.nanoseconds))
        if addingOverflow {
            Log.debug("\(#fileID): Unable to create tx id due to adding overflow of '\(validStartDate)'")
            throw WalletError.failedToBuildTx
        }

        let validStart = Timestamp(fromUnixTimestampNanos: unixTimestampNSec)

        return TransactionId.withValidStart(accountId, validStart)
    }

    private func makeTransferTransaction(
        amount: Amount,
        sourceAccountId: AccountId,
        destinationAccountId: AccountId
    ) throws -> TransferTransaction {
        let transactionValue = amount.value * pow(Decimal(10), amount.decimals)
        let transactionRoundedValue = transactionValue.rounded(roundingMode: .down)

        switch amount.type {
        case .coin:
            let transactionAmount = try Hbar(transactionRoundedValue, .tinybar)
            return TransferTransaction()
                .hbarTransfer(sourceAccountId, transactionAmount.negated())
                .hbarTransfer(destinationAccountId, transactionAmount)
        case .token(let token):
            let tokenId = try TokenId.fromSolidityAddressOrString(token.contractAddress)
            let transactionAmount = transactionRoundedValue.int64Value
            return TransferTransaction()
                .tokenTransfer(tokenId, sourceAccountId, -transactionAmount)
                .tokenTransfer(tokenId, destinationAccountId, transactionAmount)
        case .reserve, .feeResource:
            throw WalletError.failedToBuildTx
        }
    }

    private func logTransferTransaction(_ transaction: TransferTransaction) {
        let nodeAccountIds = transaction.nodeAccountIds?.toSet() ?? []
        let transactionId = transaction.transactionId?.toString() ?? "unknown"
        let networkNodes = client.network.filter { nodeAccountIds.contains($0.value) }
        Log.debug("\(#fileID): Constructed tx '\(transactionId)' with the following network nodes: \(networkNodes)")
    }
}

// MARK: - Auxiliary types

extension HederaTransactionBuilder {
    struct TokenAssociation {
        let accountId: String
        let contractAddress: String
    }

    /// Auxiliary type that hides all implementation details (including dependency on `Hedera iOS SDK`).
    struct CompiledTransaction {
        private let curve: EllipticCurve
        private let client: Hedera.Client
        private let innerTransaction: Hedera.Transaction

        fileprivate init(
            curve: EllipticCurve,
            client: Hedera.Client,
            innerTransaction: Hedera.Transaction
        ) {
            self.curve = curve
            self.client = client
            self.innerTransaction = innerTransaction
        }

        func hashesToSign() throws -> [Data] {
            let dataToSign = try innerTransaction.signedTransactionsData()
            switch curve {
            case .ed25519, .ed25519_slip0010:
                // When using EdDSA, the original transaction is signed, not its hashes or something else
                return dataToSign
            case .secp256k1:
                return dataToSign.map { $0.sha3(.keccak256) }
            default:
                throw HederaError.unsupportedCurve(curveName: curve.rawValue)
            }
        }

        func addSignatures(_ publicKey: PublicKey, _ signatures: [Data]) {
            innerTransaction.addSignatures(publicKey, signatures)
        }

        func sendAndGetHash() async throws -> String {
            return try await innerTransaction
                .execute(client)
                .transactionId
                .toString()
        }
    }
}

// MARK: - Convenience extensions

private extension Hedera.Transaction {
    /// Same as `Hedera.Transaction.nodeAccountIds(_:)`, but with empty list checking.
    @discardableResult
    func nodeAccountIdsIfNotEmpty(_ nodeAccountIds: [AccountId]?) -> Self {
        if let nodeAccountIds = nodeAccountIds?.nilIfEmpty {
            return self.nodeAccountIds(nodeAccountIds)
        }

        return self
    }
}

private extension Hedera.EntityId {
    /// A dumb convenience factory method for parsing entity IDs in both `<shard>.<realm>.<last>` (Hedera native)
    /// and `[0x]40*HEXDIG` (Solidity/EVM) forms.
    static func fromSolidityAddressOrString<S: StringProtocol>(_ input: S) throws -> Self {
        // Solidity/EVM address parsing rules are stricter, so we're trying to parse Solidity/EVM addresses first
        return try (try? fromSolidityAddress(input)) ?? fromString(input)
    }
}

// MARK: - Unit tests support

extension HederaTransactionBuilder.CompiledTransaction {
    /// - Note: For use in unit tests only or set send transaction error.
    func toBytes() throws -> Data {
        return try innerTransaction.toBytes()
    }
}
