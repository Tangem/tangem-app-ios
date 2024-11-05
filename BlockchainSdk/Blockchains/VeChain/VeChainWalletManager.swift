//
//  VeChainWalletManager.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 18.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class VeChainWalletManager: BaseManager {
    private let networkService: VeChainNetworkService
    private let transactionBuilder: VeChainTransactionBuilder

    private var energyToken: Token {
        return cardTokens.first(where: \.isEnergyToken) ?? Constants.energyToken
    }

    init(
        wallet: Wallet,
        networkService: VeChainNetworkService,
        transactionBuilder: VeChainTransactionBuilder
    ) {
        self.networkService = networkService
        self.transactionBuilder = transactionBuilder
        super.init(wallet: wallet)
    }

    @available(*, unavailable)
    override init(wallet: Wallet) {
        fatalError("\(#function) has not been implemented")
    }

    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        let accountInfoPublisher = networkService
            .getAccountInfo(address: wallet.address)

        let transactionStatusesPublisher = wallet
            .pendingTransactions
            .publisher
            .setFailureType(to: Error.self)
            .withWeakCaptureOf(self)
            .flatMap { walletManager, transaction in
                return walletManager.networkService.getTransactionInfo(transactionHash: transaction.hash)
            }
            .collect()

        // Although multiple contract calls can be aggregated into a single request, API docs says nothing
        // about the order of the results of these contract calls in the response.
        // Therefore requests are sent in a one-to-one manner, one request per token.
        let tokenBalancesPublisher = cardTokens
            .filter { $0 != Constants.energyToken } // Balance of energy token (VTHO) is fetched in the `getAccountInfo(address:)` method call above
            .publisher
            .setFailureType(to: Error.self)
            .withWeakCaptureOf(self)
            .flatMap { walletManager, token in
                return walletManager
                    .networkService
                    .getBalance(of: token, for: walletManager.wallet.address)
            }
            .collect()

        cancellable = Publishers.CombineLatest3(accountInfoPublisher, transactionStatusesPublisher, tokenBalancesPublisher)
            .sink(
                receiveCompletion: { [weak self] result in
                    switch result {
                    case .failure(let error):
                        self?.wallet.clearAmounts()
                        completion(.failure(error))
                    case .finished:
                        completion(.success(()))
                    }
                },
                receiveValue: { [weak self] input in
                    let (accountInfo, transactionsInfo, tokenBalanceAmounts) = input
                    self?.updateWallet(
                        accountInfo: accountInfo,
                        transactionsInfo: transactionsInfo,
                        tokenBalanceAmounts: tokenBalanceAmounts
                    )
                }
            )
    }

    override func addToken(_ token: Token) {
        let tokenAmount = wallet.amounts[.token(value: Constants.energyToken)]

        super.addToken(token)

        // When the real "VeThor" energy token is being added to the token list,
        // we're trying to migrate the balance from the fallback energy token to the real one
        if token.isEnergyToken, let energyTokenAmount = tokenAmount {
            wallet.clearAmount(for: Constants.energyToken)
            wallet.add(tokenValue: energyTokenAmount.value, for: token)
        }
    }

    override func removeToken(_ token: Token) {
        let tokenAmount = wallet.amounts[.token(value: token)]

        super.removeToken(token)

        // When the real "VeThor" energy token is being deleted from the token list,
        // we're trying to migrate the balance from the real energy token to the fallback one
        if token.isEnergyToken, let energyTokenAmount = tokenAmount {
            wallet.clearAmount(for: token)
            wallet.add(tokenValue: energyTokenAmount.value, for: Constants.energyToken)
        }
    }

    private func updateWallet(
        accountInfo: VeChainAccountInfo,
        transactionsInfo: [VeChainTransactionInfo],
        tokenBalanceAmounts: [Amount]
    ) {
        let amounts = [
            accountInfo.amount,
            accountInfo.energyAmount(with: energyToken),
        ] + tokenBalanceAmounts
        amounts.forEach { wallet.add(amount: $0) }

        let completedTransactionHashes = transactionsInfo
            .compactMap(\.transactionHash)
            .toSet()
        wallet.removePendingTransaction(where: completedTransactionHashes.contains(_:))
    }

    private func updateWalletWithPendingTransaction(_ transaction: Transaction, sendResult: TransactionSendResult) {
        let mapper = PendingTransactionRecordMapper()
        let pendingTransaction = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: sendResult.hash)

        wallet.addPendingTransaction(pendingTransaction)
    }

    private func makeTransactionForFeeCalculation(
        amount: Amount,
        destination: String,
        feeParams: VeChainFeeParams
    ) -> Transaction {
        // Doesn't affect fee calculation
        let dummyBlockInfo = VeChainBlockInfo(
            blockId: "",
            blockRef: 1,
            blockNumber: 1
        )
        // Doesn't affect fee calculation
        let dummyParams = VeChainTransactionParams(
            publicKey: wallet.publicKey,
            lastBlockInfo: dummyBlockInfo,
            nonce: 1
        )
        // Doesn't affect fee calculation
        let dummyFee = Fee(.zeroCoin(for: wallet.blockchain), parameters: feeParams)

        return Transaction(
            amount: amount,
            fee: dummyFee,
            sourceAddress: wallet.address,
            destinationAddress: destination,
            changeAddress: wallet.address,
            params: dummyParams
        )
    }

    private func getVMGas(amount: Amount, destination: String) -> AnyPublisher<Int, Error> {
        switch amount.type {
        case .coin:
            return .justWithError(output: .zero)
        case .token(let value):
            return networkService.getVMGas(token: value, amount: amount, source: wallet.address, destination: destination)
        case .reserve, .feeResource:
            return .anyFail(error: WalletError.failedToGetFee)
        }
    }
}

// MARK: - WalletManager protocol conformance

extension VeChainWalletManager: WalletManager {
    var currentHost: String { networkService.host }

    var allowsFeeSelection: Bool { true }

    func getFee(
        amount: Amount,
        destination: String
    ) -> AnyPublisher<[Fee], Error> {
        return getVMGas(amount: amount, destination: destination)
            .withWeakCaptureOf(self)
            .map { walletManager, vmGas in
                let transactions = VeChainFeeParams.TransactionPriority.allCases.map { priority in
                    return walletManager.makeTransactionForFeeCalculation(
                        amount: amount,
                        destination: destination,
                        feeParams: VeChainFeeParams(priority: priority, vmGas: vmGas)
                    )
                }

                return (transactions, vmGas)
            }
            .withWeakCaptureOf(self)
            .tryMap { walletManager, input in
                let (transactions, vmGas) = input
                let transactionInputs = try transactions.map { transaction in
                    try walletManager.transactionBuilder.buildInputForFeeCalculation(transaction: transaction)
                }

                return (transactionInputs, vmGas)
            }
            .withWeakCaptureOf(self)
            .map { walletManager, input in
                let (transactionInputs, vmGas) = input
                let feeCalculator = VeChainFeeCalculator(isTestnet: walletManager.wallet.blockchain.isTestnet)
                let amountType: Amount.AmountType = .token(value: walletManager.energyToken)

                return transactionInputs.map { feeCalculator.fee(for: $0, amountType: amountType, vmGas: vmGas) }
            }
            .eraseToAnyPublisher()
    }

    func send(
        _ transaction: Transaction,
        signer: TransactionSigner
    ) -> AnyPublisher<TransactionSendResult, SendTxError> {
        return networkService
            .getLatestBlockInfo()
            .withWeakCaptureOf(self)
            .map { walletManager, lastBlockInfo in
                // Using a random nonce value for a new transaction is totally fine,
                // see https://docs.vechain.org/core-concepts/transactions/transaction-model for details
                return VeChainTransactionParams(
                    publicKey: walletManager.wallet.publicKey,
                    lastBlockInfo: lastBlockInfo,
                    nonce: .random(in: 1 ..< UInt.max)
                )
            }
            .withWeakCaptureOf(self)
            .tryMap { walletManager, transactionParams -> (Data, VeChainTransactionParams) in
                let transaction = transaction.then { $0.params = transactionParams }
                let hash = try walletManager.transactionBuilder.buildForSign(transaction: transaction)

                return (hash, transactionParams)
            }
            .flatMap { hash, transactionParams in
                return signer
                    .sign(hash: hash, walletPublicKey: transactionParams.publicKey)
                    .map { ($0, hash, transactionParams) }
            }
            .withWeakCaptureOf(self)
            .tryMap { walletManager, input in
                let (signature, hash, transactionParams) = input
                let transaction = transaction.then { $0.params = transactionParams }

                return try walletManager.transactionBuilder.buildForSend(
                    transaction: transaction,
                    hash: hash,
                    signature: signature
                )
            }
            .withWeakCaptureOf(self)
            .flatMap { walletManager, rawTransactionData in
                return walletManager
                    .networkService
                    .send(transaction: rawTransactionData)
                    .mapSendError(tx: rawTransactionData.hexString.lowercased())
            }
            .eraseSendError()
            .withWeakCaptureOf(self)
            .handleEvents(
                receiveOutput: { walletManager, sendResult in
                    walletManager.updateWalletWithPendingTransaction(transaction, sendResult: sendResult)
                }
            )
            .map(\.1)
            .eraseToAnyPublisher()
    }
}

// MARK: - Constants

extension VeChainWalletManager {
    enum Constants {
        /// A local energy token ("VeThor"), used as a fallback for fee calculation when
        /// the user doesn't have a real "VeThor" token added to the token list.
        ///
        /// See https://docs.vechain.org/introduction-to-vechain/dual-token-economic-model/vethor-vtho for details and specs.
        static let energyToken = Token(
            name: "VeThor",
            symbol: "VTHO",
            contractAddress: "0x0000000000000000000000000000456e65726779",
            decimalCount: 18,
            id: "vethor-token"
        )
    }
}

// MARK: - Convenience extensions

private extension Token {
    var isEnergyToken: Bool {
        let energyTokenContractAddress = VeChainWalletManager.Constants.energyToken.contractAddress

        return contractAddress.caseInsensitiveCompare(energyTokenContractAddress) == .orderedSame
    }
}
