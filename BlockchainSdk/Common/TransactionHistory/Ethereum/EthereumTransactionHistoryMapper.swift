//
//  EthereumTransactionHistoryMapper.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 26.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

final class EthereumTransactionHistoryMapper {
    private let blockchain: Blockchain
    private var transactionIndicesCounter: [String: Int] = [:]

    private var decimalValue: Decimal {
        blockchain.decimalValue
    }

    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }
}

// MARK: - TransactionHistoryMapper protocol conformance

extension EthereumTransactionHistoryMapper: TransactionHistoryMapper {
    func mapToTransactionRecords(
        _ response: BlockBookAddressResponse,
        walletAddress: String,
        amountType: Amount.AmountType
    ) throws -> [TransactionRecord] {
        guard let transactions = response.transactions?.nilIfEmpty else {
            return []
        }

        return try transactions
            .reduce(into: []) { partialResult, transaction in
                guard let feeValue = Decimal(stringValue: transaction.fees) else {
                    Log.log("Transaction \(transaction) doesn't contain a required information")
                    return
                }

                switch amountType {
                case .coin, .reserve:
                    guard let info = extractTransactionInfo(from: transaction, walletAddress: walletAddress) else {
                        return
                    }

                    partialResult += mapToTransactionRecords(
                        transaction: transaction,
                        transactionInfos: [info],
                        amountType: amountType,
                        feeValue: feeValue
                    )
                case .token(let token):
                    guard let transfers = transaction.tokenTransfers?.nilIfEmpty else {
                        return
                    }

                    let outgoingTransactionInfos = extractTransactionInfos(
                        from: transfers,
                        token: token,
                        walletAddress: walletAddress,
                        isOutgoing: true
                    )
                    let incomingTransactionInfos = extractTransactionInfos(
                        from: transfers,
                        token: token,
                        walletAddress: walletAddress,
                        isOutgoing: false
                    )
                    partialResult += mapToTransactionRecords(
                        transaction: transaction,
                        transactionInfos: outgoingTransactionInfos + incomingTransactionInfos,
                        amountType: amountType,
                        feeValue: feeValue
                    )
                case .feeResource:
                    throw BlockchainSdkError.notImplemented
                }
            }
    }

    func reset() {
        transactionIndicesCounter.removeAll()
    }
}

// MARK: - Private

private extension EthereumTransactionHistoryMapper {
    func status(_ transaction: BlockBookAddressResponse.Transaction) -> TransactionRecord.TransactionStatus {
        guard let status = transaction.ethereumSpecific?.status else {
            return transaction.confirmations > 0 ? .confirmed : .unconfirmed
        }

        switch status {
        case .failure:
            return .failed
        case .ok:
            return .confirmed
        case .pending:
            return .unconfirmed
        }
    }

    /// Extracts the transaction info for a `coin` transfer.
    func extractTransactionInfo(
        from transaction: BlockBookAddressResponse.Transaction,
        walletAddress: String
    ) -> TransactionInfo? {
        guard let vin = transaction.compat.vin.first, let sourceAddress = vin.addresses.first else {
            Log.log("Source information in transaction \(transaction) not found")
            return nil
        }

        guard let vout = transaction.compat.vout.first, let destinationAddress = vout.addresses.first else {
            Log.log("Destination information in transaction \(transaction) not found")
            return nil
        }

        guard
            sourceAddress.caseInsensitiveEquals(to: walletAddress) || destinationAddress.caseInsensitiveEquals(to: walletAddress)
        else {
            Log.log("Unrelated transaction \(transaction) received")
            return nil
        }

        guard let transactionValue = Decimal(stringValue: transaction.value) else {
            Log.log("Transaction with invalid value \(transaction) received")
            return nil
        }

        let transactionAmount = transactionValue / blockchain.decimalValue
        let isOutgoing = sourceAddress.caseInsensitiveEquals(to: walletAddress)

        let source = TransactionRecord.Source(
            address: sourceAddress,
            amount: transactionAmount
        )

        // We can receive a data only like "0x" and then we should delete this prefix
        let hasData = transaction.ethereumSpecific?.data?.removeHexPrefix().isEmpty == false
        let hasTokenTransfers = transaction.tokenTransfers?.isEmpty == false
        let isContract = hasData || hasTokenTransfers
        let destination = TransactionRecord.Destination(
            address: isContract ? .contract(destinationAddress) : .user(destinationAddress),
            amount: transactionAmount
        )

        return TransactionInfo(
            source: source,
            destination: destination,
            isOutgoing: isOutgoing
        )
    }

    /// Extracts the transaction info for a `token` transfer.
    func extractTransactionInfos(
        from tokenTransfers: [BlockBookAddressResponse.TokenTransfer],
        token: Token,
        walletAddress: String,
        isOutgoing: Bool
    ) -> [TransactionInfo] {
        let filteredTokenTransfers = tokenTransfers
            .filter { transfer in
                // Double check to exclude token transfers sent to self.
                // Actually, this is a feasible case, but we don't support such transfers at the moment
                if isOutgoing {
                    return transfer.from.caseInsensitiveEquals(to: walletAddress) && !transfer.to.caseInsensitiveEquals(to: walletAddress)
                }
                return transfer.to.caseInsensitiveEquals(to: walletAddress) && !transfer.from.caseInsensitiveEquals(to: walletAddress)
            }
            .filter { transfer in
                // Double check to exclude token transfers for different tokens (just in case)
                guard let contract = transfer.compat.contract else {
                    return false
                }
                return token.contractAddress.caseInsensitiveEquals(to: contract)
            }

        let otherAddresses: [String]
        let groupedFilteredTokenTransfers: [String: [BlockBookAddressResponse.TokenTransfer]]

        if isOutgoing {
            otherAddresses = filteredTokenTransfers.uniqueProperties(\.to)
            groupedFilteredTokenTransfers = filteredTokenTransfers.grouped(by: \.to)
        } else {
            otherAddresses = filteredTokenTransfers.uniqueProperties(\.from)
            groupedFilteredTokenTransfers = filteredTokenTransfers.grouped(by: \.from)
        }

        return otherAddresses.reduce(into: []) { partialResult, otherAddress in
            let transfers = groupedFilteredTokenTransfers[otherAddress, default: []]

            partialResult += transfers.compactMap { transfer in
                guard let value = Decimal(stringValue: transfer.value) else {
                    Log.log("Token transfer \(transfer) with invalid value received")
                    return nil
                }

                let decimalValue = pow(10, transfer.decimals)
                let transactionAmount = value / decimalValue

                let source = TransactionRecord.Source(
                    address: isOutgoing ? walletAddress : otherAddress,
                    amount: transactionAmount
                )

                let destination = TransactionRecord.Destination(
                    address: .user(isOutgoing ? otherAddress : walletAddress),
                    amount: transactionAmount
                )

                return TransactionInfo(
                    source: source,
                    destination: destination,
                    isOutgoing: isOutgoing
                )
            }
        }
    }

    func transactionType(_ transaction: BlockBookAddressResponse.Transaction) -> TransactionRecord.TransactionType {
        let ethereumSpecific = transaction.ethereumSpecific
        let methodId = ethereumSpecific?.parsedData?.methodId ?? methodIdFromRawData(ethereumSpecific?.data)

        guard let methodId = methodId else {
            return .transfer
        }

        // MethodId is empty for the coin transfers
        if methodId.isEmpty {
            return .transfer
        }

        return .contractMethodIdentifier(id: methodId)
    }

    func methodIdFromRawData(_ rawData: String?) -> String? {
        // EVM method name has a length of 4 bytes
        let methodIdLength = 8

        guard
            let methodId = rawData?.stripHexPrefix().prefix(methodIdLength),
            methodId.count == methodIdLength
        else {
            return nil
        }

        return String(methodId).addHexPrefix()
    }

    func tokenTransfers(_ transaction: BlockBookAddressResponse.Transaction) -> [TransactionRecord.TokenTransfer]? {
        guard let tokenTransfers = transaction.tokenTransfers else {
            return nil
        }

        return tokenTransfers.map { transfer -> TransactionRecord.TokenTransfer in
            let amount = Decimal(stringValue: transfer.value) ?? 0
            return TransactionRecord.TokenTransfer(
                source: transfer.from,
                destination: transfer.to,
                amount: amount,
                name: transfer.name,
                symbol: transfer.symbol,
                decimals: transfer.decimals,
                contract: transfer.compat.contract
            )
        }
    }

    func mapToTransactionRecords(
        transaction: BlockBookAddressResponse.Transaction,
        transactionInfos: [TransactionInfo],
        amountType: Amount.AmountType,
        feeValue: Decimal
    ) -> [TransactionRecord] {
        let hash = transaction.txid
        let fee = Fee(Amount(with: blockchain, value: feeValue / blockchain.decimalValue))

        return transactionInfos.map { transactionInfo in
            let index = transactionIndicesCounter[hash, default: 0]
            transactionIndicesCounter[hash] = index + 1

            return TransactionRecord(
                hash: hash,
                index: index,
                source: .single(transactionInfo.source),
                destination: .single(transactionInfo.destination),
                fee: fee,
                status: status(transaction),
                isOutgoing: transactionInfo.isOutgoing,
                type: transactionType(transaction),
                date: Date(timeIntervalSince1970: TimeInterval(transaction.blockTime)),
                tokenTransfers: tokenTransfers(transaction)
            )
        }
    }
}

// MARK: - Convenience types

private extension EthereumTransactionHistoryMapper {
    /// Intermediate model for simpler mapping.
    struct TransactionInfo {
        let source: TransactionRecord.Source
        let destination: TransactionRecord.Destination
        let isOutgoing: Bool
    }
}
