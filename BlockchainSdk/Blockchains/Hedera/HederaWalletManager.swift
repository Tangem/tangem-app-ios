//
//  HederaWalletManager.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 25.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import struct Hedera.AccountId

final class HederaWalletManager: BaseManager {
    fileprivate typealias AssociatedTokens = Set<String>

    private let networkService: HederaNetworkService
    private let transactionBuilder: HederaTransactionBuilder
    private let dataStorage: BlockchainDataStorage
    private let accountCreator: AccountCreator

    /// HBARs per 1 USD
    private var tokenAssociationFeeExchangeRate: Decimal?
    private var associatedTokens: AssociatedTokens?

    private var storageKeySuffix: String {
        return wallet
            .publicKey
            .blockchainKey
            .getSha256()
            .hexString
    }

    // Public key as a masked string (only the last four characters are revealed), suitable for use in logs
    private lazy var maskedPublicKey: String = {
        let length = 4
        let publicKey = wallet.publicKey.blockchainKey.hexString

        return publicKey
            .dropLast(length)
            .map { _ in "•" }
            .joined()
        + publicKey.suffix(length)
    }()

    // MARK: - Initialization/Deinitialization

    init(
        wallet: Wallet,
        networkService: HederaNetworkService,
        transactionBuilder: HederaTransactionBuilder,
        accountCreator: AccountCreator,
        dataStorage: BlockchainDataStorage
    ) {
        self.networkService = networkService
        self.transactionBuilder = transactionBuilder
        self.accountCreator = accountCreator
        self.dataStorage = dataStorage
        super.init(wallet: wallet)
    }

    @available(*, unavailable)
    override init(wallet: Wallet) {
        fatalError("\(#function) has not been implemented")
    }

    // MARK: - Wallet update

    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        cancellable = loadCachedAssociatedTokensIfNeeded()
            .withWeakCaptureOf(self)
            .flatMap { walletManager, _ in
                return walletManager.getAccountId()
            }
            .withWeakCaptureOf(self)
            .flatMap { walletManager, accountId in
                return Publishers.CombineLatest(
                    walletManager.networkService.getBalance(accountId: accountId),
                    walletManager.makePendingTransactionsInfoPublisher()
                )
            }
            .withWeakCaptureOf(self)
            .flatMap { walletManager, input in
                let (accountBalance, transactionsInfo) = input
                let alreadyAssociatedTokens = accountBalance.associatedTokensContractAddresses

                return walletManager
                    .makeTokenAssociationFeeExchangeRatePublisher(alreadyAssociatedTokens: alreadyAssociatedTokens)
                    .map { exchangeRate in
                        return (accountBalance, transactionsInfo, exchangeRate)
                    }
            }
            .sink(
                receiveCompletion: { [weak self] result in
                    switch result {
                    case .failure(let error):
                        // We intentionally don't want to clear current token associations on failure
                        self?.wallet.clearAmounts()
                        completion(.failure(error))
                    case .finished:
                        completion(.success(()))
                    }
                },
                receiveValue: { [weak self] accountBalance, transactionsInfo, exchangeRate in
                    self?.updateWallet(accountBalance: accountBalance, transactionsInfo: transactionsInfo)
                    self?.updateWalletTokens(accountBalance: accountBalance, exchangeRate: exchangeRate)
                }
            )
    }

    private func updateWallet(accountBalance: HederaAccountBalance, transactionsInfo: [HederaTransactionInfo]) {
        let completedTransactionHashes = transactionsInfo
            .filter { !$0.isPending }
            .map { $0.transactionHash }

        wallet.removePendingTransaction(where: completedTransactionHashes.contains(_:))
        wallet.add(coinValue: Decimal(accountBalance.hbarBalance) / wallet.blockchain.decimalValue)
    }

    private func updateWalletTokens(accountBalance: HederaAccountBalance, exchangeRate: HederaExchangeRate?) {
        saveAssociatedTokensIfNeeded(newValue: accountBalance.associatedTokensContractAddresses)
        tokenAssociationFeeExchangeRate = exchangeRate?.nextHBARPerUSD

        let allTokenBalances = accountBalance.tokenBalances.reduce(into: [:]) { result, element in
            result[element.contractAddress] = Decimal(element.balance) / pow(10, element.decimalCount)
        }

        // Using HTS tokens balances from a remote list of tokens for tokens in a local list
        cardTokens
            .map { Amount(with: $0, value: allTokenBalances[$0.contractAddress] ?? .zero) }
            .forEach { wallet.add(amount: $0) }
    }

    private func updateWalletWithPendingTransferTransaction(_ transaction: Transaction, sendResult: TransactionSendResult) {
        let mapper = HederaPendingTransactionRecordMapper(blockchain: wallet.blockchain)
        let pendingTransaction = mapper.mapToTransferRecord(transaction: transaction, hash: sendResult.hash)
        wallet.addPendingTransaction(pendingTransaction)
    }

    private func updateWalletWithPendingTokenAssociationTransaction(_ token: Token, sendResult: TransactionSendResult) {
        let mapper = HederaPendingTransactionRecordMapper(blockchain: wallet.blockchain)
        let pendingTransaction = mapper.mapToTokenAssociationRecord(token: token, hash: sendResult.hash, accountId: wallet.address)
        wallet.addPendingTransaction(pendingTransaction)
    }

    private func updateWalletAddress(accountId: String) {
        let address = PlainAddress(value: accountId, publicKey: wallet.publicKey, type: .default)
        wallet.set(address: address)
    }

    private func makeTokenAssociationFeeExchangeRatePublisher(
        alreadyAssociatedTokens: AssociatedTokens
    ) -> some Publisher<HederaExchangeRate?, Error> {
        if cardTokens.allSatisfy({ alreadyAssociatedTokens.contains($0.contractAddress) }) {
            // All added tokens (from `cardTokens`) are already associated with the current account;
            // therefore there is no point in requesting an exchange rate to calculate the token association fee
            //
            // Performing an early exit
            return Just.justWithError(output: nil)
        }

        return networkService
            .getExchangeRate()
            .map { $0 as HederaExchangeRate? }  // Combine can't implicitly bridge `Publisher<T, Error>` to `Publisher<T?, Error`
            .replaceError(with: nil)    // Token association fee request is auxiliary and shouldn't cause the entire reactive chain to fail
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    private func makePendingTransactionsInfoPublisher() -> some Publisher<[HederaTransactionInfo], Error> {
        return wallet
            .pendingTransactions
            .publisher
            .setFailureType(to: Error.self)
            .withWeakCaptureOf(self)
            .flatMap { walletManager, pendingTransaction in
                return walletManager.networkService.getTransactionInfo(transactionHash: pendingTransaction.hash)
            }
            .collect()
    }

    // MARK: - Account ID fetching, caching and creation

    /// Used to query the status of the `receiving` (`destination`) account.
    private func doesAccountExist(destination: String) -> some Publisher<Bool, Error> {
        return Deferred {
            return Future { promise in
                let result = Result { try Hedera.AccountId(parsing: destination) }
                promise(result)
            }
        }
        .withWeakCaptureOf(self)
        .flatMap { walletManager, accountId in
            // Accounts with an account ID and/or EVM address are considered existing accounts
            let accountHasValidAccountIdOrEVMAddress = accountId.num != 0 || accountId.evmAddress != nil

            if accountHasValidAccountIdOrEVMAddress {
                return Just(true)
                    .eraseToAnyPublisher()
            }

            guard let alias = accountId.alias else {
                // Perhaps an unreachable case: account doesn't have an account ID, EVM address, or account alias
                return Just(false)
                    .eraseToAnyPublisher()
            }

            // Any error returned from the API is treated as a non-existent account, just in case
            return walletManager
                .networkService
                .getAccountInfo(publicKey: alias.toBytesRaw())  // ECDSA key must be in a compressed form
                .map { _ in true }
                .replaceError(with: false)
                .eraseToAnyPublisher()
        }
    }

    /// - Note: Has a side-effect: updates local model (`wallet.address`) if needed.
    private func getAccountId() -> some Publisher<String, Error> {
        let maskedPublicKey = maskedPublicKey

        if let accountId = wallet.address.nilIfEmpty {
            Log.debug("\(#fileID): Hedera account ID for public key \(maskedPublicKey) obtained from the Wallet")
            return Just.justWithError(output: accountId)
        }

        return getCachedAccountId()
            .withWeakCaptureOf(self)
            .handleEvents(receiveOutput: { walletManager, accountId in
                walletManager.updateWalletAddress(accountId: accountId)
                Log.debug("\(#fileID): Hedera account ID for public key \(maskedPublicKey) saved to the Wallet")
            })
            .map(\.1)
            .eraseToAnyPublisher()
    }

    /// Performs a reset of an already cached account id only if the 'reset version' is absent or lower
    /// than the current 'reset version' saved on disk (`Constants.accountIdResetVersion).
    private func resetCachedAccountIdIfNeeded() -> some Publisher<Void, Error> {
        let maskedPublicKey = maskedPublicKey
        let accountIdStorageKey = Constants.accountIdStorageKeyPrefix + storageKeySuffix
        let resetVersionStorageKey = Constants.accountIdResetVersionStorageKeyPrefix + storageKeySuffix

        return Just(resetVersionStorageKey)
            .setFailureType(to: Error.self)
            .withWeakCaptureOf(self)
            .asyncMap { walletManager, storageKey -> Int? in
                return await walletManager.dataStorage.get(key: storageKey)
            }
            .filter { cachedResetVersion in
                guard let cachedResetVersion else {
                    // Always perform a reset if no 'reset version' is currently saved on disk
                    return true
                }
                // Perform a reset if saved on disk 'reset version' is lower than actual
                return cachedResetVersion < Constants.accountIdResetVersion
            }
            .withWeakCaptureOf(self)
            .asyncMap { walletManager, _ in
                // Empty string is perfectly fine for using as an overriding value because account id
                // is always fetched using `nilIfEmpty` helper
                await walletManager.dataStorage.store(key: accountIdStorageKey, value: "")
                await walletManager.dataStorage.store(key: resetVersionStorageKey, value: Constants.accountIdResetVersion)
                Log.debug("\(#fileID): Hedera account ID for public key \(maskedPublicKey) was reset")
            }
            .mapToVoid()
            .replaceEmpty(with: ()) // Continue the reactive stream normally even if the `.filter` statement above returns false
    }

    /// - Note: Has a side-effect: updates local cache (`dataStorage`) if needed.
    private func getCachedAccountId() -> some Publisher<String, Error> {
        let maskedPublicKey = maskedPublicKey
        let storageKey = Constants.accountIdStorageKeyPrefix + storageKeySuffix

        return resetCachedAccountIdIfNeeded()
            .withWeakCaptureOf(self)
            .asyncMap { walletManager, _ -> String? in
                await walletManager.dataStorage.get(key: storageKey)
            }
            .withWeakCaptureOf(self)
            .flatMap { walletManager, accountId in
                if let accountId = accountId?.nilIfEmpty {
                    Log.debug("\(#fileID): Hedera account ID for public key \(maskedPublicKey) obtained from the data storage")
                    return Just.justWithError(output: accountId)
                }

                return walletManager
                    .getRemoteAccountId()
                    .withWeakCaptureOf(walletManager)
                    .asyncMap { walletManager, accountId in
                        await walletManager.dataStorage.store(key: storageKey, value: accountId)
                        Log.debug("\(#fileID): Hedera account ID for public key \(maskedPublicKey) saved to the data storage")
                        return accountId
                    }
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
    }

    /// - Note: Fetches a single existing account using the `createOrFetchAccount` method if multiple accounts exist on the Hedera network.
    /// - Note: Has a side-effect: creates a new account on the Hedera network using the `createOrFetchAccount` method if needed.
    private func getRemoteAccountId() -> some Publisher<String, Error> {
        let maskedPublicKey = maskedPublicKey

        return networkService
            .getAccountInfo(publicKey: wallet.publicKey.blockchainKey)
            .map(\.accountId)
            .handleEvents(
                receiveOutput: { _ in
                    Log.debug("\(#fileID): Hedera account ID for public key \(maskedPublicKey) obtained from the mirror node")
                },
                receiveFailure: { error in
                    Log.error(
                        """
                        \(#fileID): Failed to obtain Hedera account ID for public key \(maskedPublicKey) \
                        from the mirror node due to error: \(error.localizedDescription)
                        """
                    )
                }
            )
            .tryCatch { [weak self] error in
                guard let self else {
                    throw error
                }

                switch error {
                case HederaError.accountDoesNotExist, HederaError.multipleAccountsFound:
                    return createOrFetchAccount()
                default:
                    throw error
                }
            }
    }

    private func createOrFetchAccount() -> some Publisher<String, Error> {
        let maskedPublicKey = maskedPublicKey

        return accountCreator
            .createAccount(blockchain: wallet.blockchain, publicKey: wallet.publicKey)
            .eraseToAnyPublisher()
            .tryMap { createdAccount in
                guard let hederaCreatedAccount = createdAccount as? HederaCreatedAccount else {
                    assertionFailure("Expected entity of type '\(HederaCreatedAccount.self)', got '\(type(of: createdAccount))' instead")
                    throw HederaError.failedToCreateAccount
                }

                return hederaCreatedAccount.accountId
            }
            .handleEvents(
                receiveOutput: { _ in
                    Log.debug("\(#fileID): Hedera account ID for public key \(maskedPublicKey) obtained by creating account")
                },
                receiveFailure: { error in
                    Log.error(
                        """
                        \(#fileID): Failed to obtain Hedera account ID for public key \(maskedPublicKey) \
                        by creating account due to error: \(error.localizedDescription)
                        """
                    )
                }
            )
            .mapError(WalletError.blockchainUnavailable(underlyingError:))
    }

    // MARK: - Token associations management

    private func loadCachedAssociatedTokensIfNeeded() -> some Publisher<Void, Error> {
        guard associatedTokens == nil else {
            // Token associations are already loaded from the cache
            return Just.justWithError(output: ())
        }

        let storageKey = Constants.associatedTokensStorageKeyPrefix + storageKeySuffix

        return Just
            .justWithError(output: storageKey)
            .withWeakCaptureOf(self)
            .asyncMap { walletManager, storageKey in
                return await walletManager.dataStorage.get(key: storageKey) ?? []
            }
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .handleEvents(receiveOutput: { walletManager, cachedAssociatedTokens in
                walletManager.associatedTokens = cachedAssociatedTokens
            })
            .mapToVoid()
            .eraseToAnyPublisher()
    }

    private func saveAssociatedTokensIfNeeded(newValue: AssociatedTokens) {
        guard associatedTokens != newValue else {
            return
        }

        associatedTokens = newValue

        Task.detached { [storageKeySuffix, dataStorage] in
            let storageKey = Constants.associatedTokensStorageKeyPrefix + storageKeySuffix
            await dataStorage.store(key: storageKey, value: newValue)
        }
    }

    // MARK: - Transaction dependencies and building

    private func getFee(amount: Amount, doesAccountExistPublisher: some Publisher<Bool, Error>) -> AnyPublisher<[Fee], Error> {
        let transferFeeBase: Decimal
        switch amount.type {
        case .coin:
            transferFeeBase = Constants.cryptoTransferServiceCostInUSD
        case .token:
            transferFeeBase = Constants.tokenTransferServiceCostInUSD
        case .reserve, .feeResource:
            return .anyFail(error: WalletError.failedToGetFee)
        }

        return Publishers.CombineLatest(
            networkService.getExchangeRate(),
            doesAccountExistPublisher
        )
        .withWeakCaptureOf(self)
        .tryMap { walletManager, input in
            let (exchangeRate, doesAccountExist) = input
            let feeBase = doesAccountExist ? transferFeeBase : Constants.cryptoCreateServiceCostInUSD
            let feeValue = exchangeRate.nextHBARPerUSD * feeBase * Constants.maxFeeMultiplier
            // Hedera fee calculation involves conversion from USD to HBar units, which ultimately results in a loss of precision.
            // Therefore, the fee value is always approximate and rounding of the fee value is mandatory.
            let feeRoundedValue = feeValue.rounded(blockchain: walletManager.wallet.blockchain, roundingMode: .up)
            let feeAmount = Amount(with: walletManager.wallet.blockchain, value: feeRoundedValue)
            let fee = Fee(feeAmount)

            return [fee]
        }
        .eraseToAnyPublisher()
    }

    private static func makeTransactionValidStartDate() -> UnixTimestamp? {
        // Subtracting `validStartDateDiff` from the `Date.now` to make sure that the tx valid start date has already passed
        // The logic is the same as in the `Hedera.TransactionId.generateFrom(_:)` factory method
        let validStartDateDiff = Int.random(in: 5_000_000_000..<8_000_000_000)
        let validStartDate = Calendar.current.date(byAdding: .nanosecond, value: -validStartDateDiff, to: Date())

        return validStartDate.flatMap(UnixTimestamp.init(date:))
    }

    private func sendCompiledTransaction(
        signedUsing signer: TransactionSigner,
        transactionFactory: @escaping (_ validStartDate: UnixTimestamp) throws -> HederaTransactionBuilder.CompiledTransaction
    ) -> some Publisher<TransactionSendResult, Error> {
        return Deferred {
            return Future { (promise: Future<HederaTransactionBuilder.CompiledTransaction, Error>.Promise) in
                guard let validStartDate = Self.makeTransactionValidStartDate() else {
                    return promise(.failure(WalletError.failedToBuildTx))
                }

                let compiledTransaction = Result { try transactionFactory(validStartDate) }
                promise(compiledTransaction)
            }
        }
        .tryMap { compiledTransaction in
            let hashesToSign = try compiledTransaction.hashesToSign()
            return (hashesToSign, compiledTransaction)
        }
        .withWeakCaptureOf(self)
        .flatMap { walletManager, input in
            let (hashesToSign, compiledTransaction) = input
            return signer
                .sign(hashes: hashesToSign, walletPublicKey: walletManager.wallet.publicKey)
                .map { ($0, compiledTransaction) }
        }
        .withWeakCaptureOf(self)
        .tryMap { walletManager, input in
            let (signatures, compiledTransaction) = input
            return try walletManager
                .transactionBuilder
                .buildForSend(transaction: compiledTransaction, signatures: signatures)
        }
        .withWeakCaptureOf(self)
        .flatMap { walletManager, compiledTransaction in
            let transactionRawData = try? compiledTransaction.toBytes()
            
            return walletManager
                .networkService
                .send(transaction: compiledTransaction)
                .mapSendError(tx: transactionRawData?.hexString)
                .eraseToAnyPublisher()
        }
    }
}

// MARK: - WalletManager protocol conformance

extension HederaWalletManager: WalletManager {
    var currentHost: String { networkService.host }

    var allowsFeeSelection: Bool { false }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        let doesAccountExistPublisher = doesAccountExist(destination: destination)

        return getFee(amount: amount, doesAccountExistPublisher: doesAccountExistPublisher)
    }

    func estimatedFee(amount: Amount) -> AnyPublisher<[Fee], Error> {
        // For a rough fee estimation (calculated in this method), all destinations are considered non-existent just in case
        let doesAccountExistPublisher = Just.justWithError(output: false)

        return getFee(amount: amount, doesAccountExistPublisher: doesAccountExistPublisher)
    }

    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        return sendCompiledTransaction(signedUsing: signer) { [weak self] validStartDate in
            guard let self else {
                throw WalletError.empty
            }

            return try self.transactionBuilder
                .buildTransferTransactionForSign(
                    transaction: transaction,
                    validStartDate: validStartDate,
                    nodeAccountIds: nil
                )
        }
        .withWeakCaptureOf(self)
        .handleEvents(receiveOutput: { walletManager, sendResult in
            walletManager.updateWalletWithPendingTransferTransaction(transaction, sendResult: sendResult)
        })
        .eraseSendError()
        .map(\.1)
        .eraseToAnyPublisher()
    }
}

// MARK: - AssetRequirementsManager protocol conformance

extension HederaWalletManager: AssetRequirementsManager {
    func hasRequirements(for asset: Asset) -> Bool {
        switch asset {
        case .coin, .reserve, .feeResource:
            return false
        case .token(let token):
            return !(associatedTokens ?? []).contains(token.contractAddress)
        }
    }

    func requirementsCondition(for asset: Asset) -> AssetRequirementsCondition? {
        guard hasRequirements(for: asset) else {
            return nil
        }

        switch asset {
        case .coin, .reserve, .feeResource:
            return nil
        case .token:
            guard let tokenAssociationFeeExchangeRate else {
                return .paidTransaction
            }

            let feeValue = tokenAssociationFeeExchangeRate * Constants.tokenAssociateServiceCostInUSD
            // Hedera fee calculation involves conversion from USD to HBar units, which ultimately results in a loss of precision.
            // Therefore, the fee value is always approximate and rounding of the fee value is mandatory.
            let feeRoundedValue = feeValue.rounded(blockchain: wallet.blockchain, roundingMode: .up)
            let feeAmount = Amount(with: wallet.blockchain, value: feeRoundedValue)

            return .paidTransactionWithFee(feeAmount: feeAmount)
        }
    }

    func fulfillRequirements(for asset: Asset, signer: any TransactionSigner) -> AnyPublisher<Void, Error> {
        guard hasRequirements(for: asset) else {
            return .justWithError(output: ())
        }

        switch asset {
        case .coin, .reserve, .feeResource:
            return .justWithError(output: ())
        case .token(let token):
            return sendCompiledTransaction(signedUsing: signer) { [weak self] validStartDate in
                guard let self else {
                    throw WalletError.empty
                }

                return try self.transactionBuilder.buildTokenAssociationForSign(
                    tokenAssociation: .init(accountId: self.wallet.address, contractAddress: token.contractAddress),
                    validStartDate: validStartDate,
                    nodeAccountIds: nil
                )
            }
            .withWeakCaptureOf(self)
            .handleEvents(receiveOutput: { walletManager, sendResult in
                walletManager.updateWalletWithPendingTokenAssociationTransaction(token, sendResult: sendResult)
            })
            .mapToVoid()
            .eraseToAnyPublisher()
        }
    }
}

// MARK: - Constants

private extension HederaWalletManager {
    private enum Constants {
        static let accountIdStorageKeyPrefix = "hedera_wallet_"
        static let accountIdResetVersionStorageKeyPrefix = "hedera_wallet_reset_version_"
        static let associatedTokensStorageKeyPrefix = "hedera_associated_tokens_"
        /// https://docs.hedera.com/hedera/networks/mainnet/fees
        static let cryptoTransferServiceCostInUSD = Decimal(stringValue: "0.0001")!
        static let tokenTransferServiceCostInUSD = Decimal(stringValue: "0.001")!
        static let cryptoCreateServiceCostInUSD = Decimal(stringValue: "0.05")!
        static let tokenAssociateServiceCostInUSD = Decimal(stringValue: "0.05")!
        /// Hedera fees are low, allow 10% safety margin to allow usage of not precise fee estimate.
        static let maxFeeMultiplier = Decimal(stringValue: "1.1")!
        /// Increment if you need to reset `dataStorage` in the next version of the app.
        static let accountIdResetVersion = 1
    }
}

// MARK: - Convenience extensions

private extension HederaAccountBalance {
    var associatedTokensContractAddresses: HederaWalletManager.AssociatedTokens {
        return tokenBalances
            .map(\.contractAddress)
            .toSet()
    }
}
