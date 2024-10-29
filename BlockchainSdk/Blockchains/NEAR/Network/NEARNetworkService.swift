//
//  NEARNetworkService.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 13.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class NEARNetworkService: MultiNetworkProvider {
    let providers: [NEARNetworkProvider]
    var currentProviderIndex: Int = 0

    private let blockchain: Blockchain

    init(
        blockchain: Blockchain,
        providers: [NEARNetworkProvider]
    ) {
        self.blockchain = blockchain
        self.providers = providers
    }

    func getGasPrice() -> AnyPublisher<Decimal, Error> {
        return providerPublisher { provider in
            return provider
                .getGasPrice()
                .tryMap { result in
                    guard let gasPrice = Decimal(string: result.gasPrice) else {
                        throw WalletError.failedToParseNetworkResponse()
                    }

                    return gasPrice
                }
                .eraseToAnyPublisher()
        }
    }

    func getProtocolConfig() -> AnyPublisher<NEARProtocolConfig, Error> {
        return providerPublisher { provider in
            return provider
                .getProtocolConfig()
                .map { result in
                    let transactionCosts = result.runtimeConfig.transactionCosts
                    let actionCreationConfig = transactionCosts.actionCreationConfig.transferCost
                    let createAccountCostConfig = transactionCosts.actionCreationConfig.createAccountCost
                    let addKeyCostConfig = transactionCosts.actionCreationConfig.addKeyCost.fullAccessCost
                    let actionReceiptCreationConfig = transactionCosts.actionReceiptCreationConfig

                    let cumulativeBasicExecutionCost = Decimal(actionCreationConfig.execution)
                        + Decimal(actionReceiptCreationConfig.execution)

                    let cumulativeAdditionalExecutionCost = Decimal(createAccountCostConfig.execution)
                        + Decimal(addKeyCostConfig.execution)

                    let senderIsReceiverCumulativeBasicSendCost = Decimal(actionCreationConfig.sendSir)
                        + Decimal(actionReceiptCreationConfig.sendSir)

                    let senderIsReceiverCumulativeAdditionalSendCost = Decimal(createAccountCostConfig.sendSir)
                        + Decimal(addKeyCostConfig.sendSir)

                    let senderIsNotReceiverCumulativeBasicSendCost = Decimal(actionCreationConfig.sendNotSir)
                        + Decimal(actionReceiptCreationConfig.sendNotSir)

                    let senderIsNotReceiverCumulativeAdditionalSendCost = Decimal(createAccountCostConfig.sendNotSir)
                        + Decimal(addKeyCostConfig.sendNotSir)

                    let storageAmountPerByte = Decimal(result.runtimeConfig.storageAmountPerByte)
                        ?? NEARProtocolConfig.fallbackProtocolConfig.storageAmountPerByte

                    return NEARProtocolConfig(
                        senderIsReceiver: .init(
                            cumulativeBasicSendCost: senderIsReceiverCumulativeBasicSendCost,
                            cumulativeBasicExecutionCost: cumulativeBasicExecutionCost,
                            cumulativeAdditionalSendCost: senderIsReceiverCumulativeAdditionalSendCost,
                            cumulativeAdditionalExecutionCost: cumulativeAdditionalExecutionCost
                        ),
                        senderIsNotReceiver: .init(
                            cumulativeBasicSendCost: senderIsNotReceiverCumulativeBasicSendCost,
                            cumulativeBasicExecutionCost: cumulativeBasicExecutionCost,
                            cumulativeAdditionalSendCost: senderIsNotReceiverCumulativeAdditionalSendCost,
                            cumulativeAdditionalExecutionCost: cumulativeAdditionalExecutionCost
                        ),
                        storageAmountPerByte: storageAmountPerByte
                    )
                }
                .eraseToAnyPublisher()
        }
    }

    func getInfo(accountId: String) -> AnyPublisher<NEARAccountInfo, Error> {
        let blockchain = blockchain

        return providerPublisher { provider in
            return provider
                .getInfo(accountId: accountId)
                .tryMap { result in
                    guard let rawAmount = Decimal(string: result.amount) else {
                        throw WalletError.failedToParseNetworkResponse()
                    }

                    let value = rawAmount / blockchain.decimalValue
                    let amount = Amount(with: blockchain, value: value)

                    return NEARAccountInfo.initialized(
                        .init(
                            accountId: accountId,
                            amount: amount,
                            recentBlockHash: result.blockHash,
                            storageUsageInBytes: Decimal(result.storageUsage)
                        )
                    )
                }
                .tryCatch { error in
                    guard let apiError = error as? NEARNetworkResult.APIError, apiError.isUnknownAccount else {
                        throw error
                    }

                    return Just(NEARAccountInfo.notInitialized)
                }
                .eraseToAnyPublisher()
        }
    }

    func getAccessKeyInfo(accountId: String, publicKey: Wallet.PublicKey) -> AnyPublisher<NEARAccessKeyInfo, Error> {
        let publicKeyPayload = Constants.ed25519SerializationPrefix + publicKey.blockchainKey.base58EncodedString

        return providerPublisher { provider in
            return provider
                .getAccessKeyInfo(accountId: accountId, publicKey: publicKeyPayload)
                .map { result in
                    return NEARAccessKeyInfo(
                        currentNonce: result.nonce,
                        recentBlockHash: result.blockHash,
                        canBeUsedForTransfer: result.permission == .fullAccess
                    )
                }
                .eraseToAnyPublisher()
        }
    }

    func send(transaction: Data) -> AnyPublisher<TransactionSendResult, Error> {
        return providerPublisher { provider in
            return provider
                .sendTransactionAsync(transaction.base64EncodedString())
                .map(TransactionSendResult.init(hash:))
                .eraseToAnyPublisher()
        }
    }

    func getTransactionsInfo(accountId: String, transactionHashes: [String]) -> AnyPublisher<NEARTransactionsInfo, Error> {
        transactionHashes
            .publisher
            .setFailureType(to: Error.self)
            .withWeakCaptureOf(self)
            .flatMap { networkService, transactionHash in
                return networkService.getTransactionInfo(accountId: accountId, transactionHash: transactionHash)
            }
            .collect()
            .map(NEARTransactionsInfo.init(transactions:))
            .eraseToAnyPublisher()
    }

    private func getTransactionInfo(
        accountId: String,
        transactionHash: String
    ) -> AnyPublisher<NEARTransactionsInfo.Transaction, Error> {
        return providerPublisher { provider in
            return provider
                .getTransactionStatus(accountId: accountId, transactionHash: transactionHash)
                .map { result in
                    let status: NEARTransactionsInfo.Status
                    switch result.status {
                    case .success:
                        status = .success
                    case .failure:
                        status = .failure
                    case .other:
                        status = .other
                    }

                    return NEARTransactionsInfo.Transaction(hash: transactionHash, status: status)
                }
                .tryCatch { error -> AnyPublisher<NEARTransactionsInfo.Transaction, Error> in
                    guard let apiError = error as? NEARNetworkResult.APIError else {
                        throw error
                    }

                    // Most likely, the transaction hasn't been recorded on the chain yet
                    if apiError.isUnknownTransaction {
                        return .justWithError(output: .init(hash: transactionHash, status: .other))
                    }

                    // The transaction indeed failed
                    if apiError.isInvalidTransaction {
                        return .justWithError(output: .init(hash: transactionHash, status: .failure))
                    }

                    throw error
                }
                .eraseToAnyPublisher()
        }
    }
}

// MARK: - Constants

private extension NEARNetworkService {
    enum Constants {
        static let ed25519SerializationPrefix = "ed25519:"
    }
}
