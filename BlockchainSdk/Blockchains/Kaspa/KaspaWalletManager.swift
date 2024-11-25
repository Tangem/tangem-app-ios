//
//  KaspaWalletManager.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 10.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class KaspaWalletManager: BaseManager, WalletManager {
    private typealias IncompleteTokenTransactionsInMemoryStorage = ThreadSafeContainer<
        [KaspaIncompleteTokenTransactionStorageID: KaspaKRC20.IncompleteTokenTransactionParams]
    >

    private let txBuilder: KaspaTransactionBuilder
    private let networkService: KaspaNetworkService
    private let networkServiceKRC20: KaspaNetworkServiceKRC20
    private let dataStorage: BlockchainDataStorage
    private var incompleteTokenTransactionsInMemoryStorage: IncompleteTokenTransactionsInMemoryStorage = [:]
    private var lastLoadedCardTokens: [Token] = []

    var currentHost: String { networkService.host }
    var allowsFeeSelection: Bool { false }

    // MARK: - Initialization/Deinitialization

    init(
        wallet: Wallet,
        networkService: KaspaNetworkService,
        networkServiceKRC20: KaspaNetworkServiceKRC20,
        txBuilder: KaspaTransactionBuilder,
        dataStorage: BlockchainDataStorage
    ) {
        self.networkService = networkService
        self.networkServiceKRC20 = networkServiceKRC20
        self.txBuilder = txBuilder
        self.dataStorage = dataStorage
        super.init(wallet: wallet)
    }

    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        let unconfirmedTransactionHashes = wallet.pendingTransactions.map { $0.hash }

        cancellable = loadCachedIncompleteTokenTransactionsIfNeeded()
            .withWeakCaptureOf(self)
            .flatMap { walletManager, _ in
                Publishers.Zip(
                    walletManager.networkService.getInfo(
                        address: walletManager.wallet.address,
                        unconfirmedTransactionHashes: unconfirmedTransactionHashes
                    ),
                    walletManager.networkServiceKRC20.balance(
                        address: walletManager.wallet.address,
                        tokens: walletManager.cardTokens
                    )
                )
            }
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.wallet.clearAmounts()
                    completion(.failure(error))
                case .finished:
                    completion(.success(()))
                }
            }, receiveValue: { [weak self] kaspaAddressInfo, kaspaTokensInfo in
                self?.updateWallet(kaspaAddressInfo, tokensInfo: kaspaTokensInfo)
                completion(.success(()))
            })
    }

    func send(_ transaction: Transaction, signer: any TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        let amountType = transaction.amount.type

        switch amountType {
        case .token(let token) where transaction.params is KaspaKRC20.IncompleteTokenTransactionParams:
            return sendKaspaRevealTokenTransaction(transaction, token: token, signer: signer)
        case .token(let token):
            let comparator = KaspaKRC20.IncompleteTokenTransactionComparator()
            return sendIncompleteKaspaTokenTransactionIfPossible(
                for: amountType,
                signer: signer,
                validator: { comparator.isIncompleteTokenTransaction($0, equalTo: transaction) }
            )
            .tryCatch { [weak self] _ in
                guard let self else {
                    throw WalletError.empty
                }

                // `sendIncompleteKaspaTokenTransactionIfPossible` above attempts to re-send a cached incomplete token transaction if one exists.
                // Any errors thrown from `sendIncompleteKaspaTokenTransactionIfAvailable` resulted in sending a new token transaction (created from scratch)
                return sendKaspaTokenTransaction(transaction, token: token, signer: signer)
            }
            .eraseSendError()
            .eraseToAnyPublisher()
        case .coin, .reserve, .feeResource:
            return sendKaspaCoinTransaction(transaction, signer: signer)
        }
    }

    private func sendKaspaCoinTransaction(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        let kaspaTransaction: KaspaTransaction
        let hashes: [Data]

        do {
            let result = try txBuilder.buildForSign(transaction)
            kaspaTransaction = result.0
            hashes = result.1
        } catch {
            return .sendTxFail(error: error)
        }

        return signer.sign(hashes: hashes, walletPublicKey: wallet.publicKey)
            .tryMap { [weak self] signatures in
                guard let self = self else { throw WalletError.empty }

                return txBuilder.buildForSend(transaction: kaspaTransaction, signatures: signatures)
            }
            .flatMap { [weak self] tx -> AnyPublisher<KaspaTransactionResponse, Error> in
                guard let self = self else { return .emptyFail }

                let encodedRawTransactionData = try? JSONEncoder().encode(tx)

                return networkService
                    .send(transaction: KaspaTransactionRequest(transaction: tx))
                    .mapSendError(tx: encodedRawTransactionData?.hexString.lowercased())
                    .eraseToAnyPublisher()
            }
            .handleEvents(receiveOutput: { [weak self] in
                let mapper = PendingTransactionRecordMapper()
                let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: $0.transactionId)
                self?.wallet.addPendingTransaction(record)
            })
            .map {
                TransactionSendResult(hash: $0.transactionId)
            }
            .eraseSendError()
            .eraseToAnyPublisher()
    }

    private func sendKaspaTokenTransaction(_ transaction: Transaction, token: Token, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        let txgroup: KaspaKRC20.TransactionGroup
        let meta: KaspaKRC20.TransactionMeta
        var builtKaspaRevealTx: KaspaTransactionData?

        do {
            let result = try txBuilder.buildForSendKRC20(transaction: transaction, token: token)
            txgroup = result.0
            meta = result.1
        } catch {
            return .sendTxFail(error: error)
        }

        return signer.sign(hashes: txgroup.hashesCommit + txgroup.hashesReveal, walletPublicKey: wallet.publicKey)
            .tryMap { [weak self] signatures in
                guard let self = self else { throw WalletError.empty }
                // Build Commit & Reveal
                let commitSignatures = Array(signatures[..<txgroup.hashesCommit.count])
                let revealSignatures = Array(signatures[txgroup.hashesCommit.count...])

                let commitTx = txBuilder.buildForSend(
                    transaction: txgroup.kaspaCommitTransaction,
                    signatures: commitSignatures
                )
                let revealTx = txBuilder.buildForSendReveal(
                    transaction: txgroup.kaspaRevealTransaction,
                    commitRedeemScript: meta.redeemScriptCommit,
                    signatures: revealSignatures
                )

                builtKaspaRevealTx = revealTx

                return (commitTx, revealTx)
            }
            .withWeakCaptureOf(self)
            .flatMap { (manager, txs: (tx: KaspaTransactionData, tx2: KaspaTransactionData)) -> AnyPublisher<KaspaTransactionResponse, Error> in
                // Send Commit
                let encodedRawTransactionData = try? JSONEncoder().encode(txs.tx)

                return manager.networkService
                    .send(transaction: KaspaTransactionRequest(transaction: txs.tx))
                    .mapSendError(tx: encodedRawTransactionData?.hexString.lowercased())
                    .eraseToAnyPublisher()
            }
            .withWeakCaptureOf(self)
            .asyncMap { manager, response in
                // Store Commit
                await manager.store(incompleteTokenTransaction: meta.incompleteTransactionParams, for: token)
                return response
            }
            .eraseToAnyPublisher()
            .delay(for: .seconds(2), scheduler: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .flatMap { manager, response -> AnyPublisher<KaspaTransactionResponse, Error> in
                // Send Reveal
                guard let tx = builtKaspaRevealTx else {
                    return .anyFail(error: WalletError.failedToBuildTx)
                }

                let encodedRawTransactionData = try? JSONEncoder().encode(tx)
                return manager.networkService
                    .send(transaction: KaspaTransactionRequest(transaction: tx))
                    .mapSendError(tx: encodedRawTransactionData?.hexString.lowercased())
                    .eraseToAnyPublisher()
            }
            .handleEvents(receiveOutput: { [weak self] in
                let mapper = PendingTransactionRecordMapper()
                let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: $0.transactionId)
                self?.wallet.addPendingTransaction(record)
            })
            .withWeakCaptureOf(self)
            .asyncMap { manager, response in
                // Delete Commit
                await manager.removeIncompleteTokenTransaction(for: token)
                return TransactionSendResult(hash: response.transactionId)
            }
            .eraseSendError()
            .eraseToAnyPublisher()
    }

    private func sendIncompleteKaspaTokenTransactionIfPossible(
        for asset: Asset,
        signer: any TransactionSigner,
        validator isIncompleteTokenTransactionValid: @escaping (_ tx: KaspaKRC20.IncompleteTokenTransactionParams) -> Bool
    ) -> some Publisher<TransactionSendResult, SendTxError> {
        return Just(asset)
            .withWeakCaptureOf(self)
            .tryMap { walletManager, asset in
                guard
                    let token = asset.token,
                    let incompleteTokenTransaction = walletManager.getIncompleteTokenTransaction(for: asset)
                else {
                    throw KaspaKRC20.Error.unableToFindIncompleteTokenTransaction
                }

                guard
                    isIncompleteTokenTransactionValid(incompleteTokenTransaction)
                else {
                    throw KaspaKRC20.Error.invalidIncompleteTokenTransaction
                }

                guard
                    let tokenTransaction = walletManager.makeTransaction(from: incompleteTokenTransaction, for: token)
                else {
                    throw KaspaKRC20.Error.unableToBuildRevealTransaction
                }

                return tokenTransaction
            }
            .eraseSendError()
            .withWeakCaptureOf(self)
            .flatMap { walletManager, tokenTransaction in
                return walletManager.send(tokenTransaction, signer: signer)
            }
    }

    private func sendKaspaRevealTokenTransaction(
        _ transaction: Transaction,
        token: Token,
        signer: TransactionSigner
    ) -> AnyPublisher<TransactionSendResult, SendTxError> {
        let kaspaTransaction: KaspaTransaction
        let commitRedeemScript: KaspaKRC20.RedeemScript
        let hashes: [Data]

        guard let params = transaction.params as? KaspaKRC20.IncompleteTokenTransactionParams,
              // Here, we use fee, which is obtained from previously saved data and the hardcoded dust value
              let feeParams = transaction.fee.parameters as? KaspaKRC20.RevealTransactionFeeParameter
        else {
            return .sendTxFail(error: WalletError.failedToBuildTx)
        }

        do {
            let result = try txBuilder.buildRevealTransaction(
                sourceAddress: transaction.sourceAddress,
                params: params,
                fee: .init(feeParams.amount)
            )

            kaspaTransaction = result.transaction
            hashes = result.hashes
            commitRedeemScript = result.redeemScript
        } catch {
            return .sendTxFail(error: error)
        }

        return signer.sign(hashes: hashes, walletPublicKey: wallet.publicKey)
            .tryMap { [weak self] signatures in
                guard let self = self else { throw WalletError.empty }

                return txBuilder.buildForSendReveal(transaction: kaspaTransaction, commitRedeemScript: commitRedeemScript, signatures: signatures)
            }
            .flatMap { [weak self] tx -> AnyPublisher<KaspaTransactionResponse, Error> in
                guard let self = self else { return .emptyFail }

                let encodedRawTransactionData = try? JSONEncoder().encode(tx)

                return networkService
                    .send(transaction: KaspaTransactionRequest(transaction: tx))
                    .mapSendError(tx: encodedRawTransactionData?.hexString.lowercased())
                    .eraseToAnyPublisher()
            }
            .withWeakCaptureOf(self)
            .asyncMap { manager, input in
                // Delete Commit
                await manager.removeIncompleteTokenTransaction(for: token)
                return TransactionSendResult(hash: input.transactionId)
            }
            .eraseSendError()
            .eraseToAnyPublisher()
    }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        let blockchain = wallet.blockchain
        let isTestnet = blockchain.isTestnet
        let source = wallet.address

        let transaction = Transaction(
            amount: amount,
            fee: Fee(Amount.zeroCoin(for: blockchain)),
            sourceAddress: source,
            destinationAddress: destination,
            changeAddress: source
        )

        switch amount.type {
        case .token(let token):
            return Result {
                try txBuilder.buildForMassCalculationKRC20(transaction: transaction, token: token)
            }
            .publisher
            .withWeakCaptureOf(networkService)
            .flatMap { networkService, transactionData in
                networkService.mass(data: transactionData)
                    .zip(networkService.feeEstimate())
            }
            .map { mass, feeEstimate in
                let feeMapper = KaspaFeeMapper(isTestnet: isTestnet)
                return feeMapper.mapTokenFee(mass: Decimal(mass.mass), feeEstimate: feeEstimate)
            }
            .eraseToAnyPublisher()

        default:
            return Result {
                try txBuilder.buildForMassCalculation(transaction: transaction)
            }
            .publisher
            .withWeakCaptureOf(networkService)
            .flatMap { networkService, transactionData in
                networkService.mass(data: transactionData)
                    .zip(networkService.feeEstimate())
            }
            .map { mass, feeEstimate in
                let feeMapper = KaspaFeeMapper(isTestnet: isTestnet)
                return feeMapper.mapFee(mass: mass, feeEstimate: feeEstimate)
            }
            .eraseToAnyPublisher()
        }
    }

    private func updateWallet(_ info: KaspaAddressInfo, tokensInfo: [Token: Result<KaspaBalanceResponseKRC20, Error>]) {
        wallet.add(amount: Amount(with: wallet.blockchain, value: info.balance))
        txBuilder.setUnspentOutputs(info.unspentOutputs)

        for token in tokensInfo {
            switch token.value {
            case .success(let tokenBalance):
                let decimalTokenBalance = (Decimal(stringValue: tokenBalance.result.first?.balance) ?? 0) / token.key.decimalValue
                wallet.add(tokenValue: decimalTokenBalance, for: token.key)
            case .failure:
                wallet.clearAmount(for: token.key)
            }
        }

        wallet.removePendingTransaction { hash in
            info.confirmedTransactionHashes.contains(hash)
        }
    }

    // MARK: - KRC20 Tokens management

    private func loadCachedIncompleteTokenTransactionsIfNeeded() -> some Publisher<Void, Error> {
        guard cardTokens != lastLoadedCardTokens else {
            // Incomplete transactions for the current set of tokens are already loaded from the cache
            return Just.justWithError(output: ())
        }

        return Just
            .justWithError(output: cardTokens)
            .withWeakCaptureOf(self)
            .asyncMap { walletManager, cardTokens in
                let dataStorage = walletManager.dataStorage
                let inMemoryStorage = walletManager.incompleteTokenTransactionsInMemoryStorage

                let storedTransactionParams = await withTaskGroup(
                    of: (KaspaIncompleteTokenTransactionStorageID, KaspaKRC20.IncompleteTokenTransactionParams?).self,
                    returning: [KaspaIncompleteTokenTransactionStorageID: KaspaKRC20.IncompleteTokenTransactionParams].self
                ) { taskGroup in
                    for token in cardTokens {
                        taskGroup.addTask {
                            let storageId = token.asStorageId
                            return (storageId, await dataStorage.get(key: storageId.id))
                        }
                    }

                    return await taskGroup.reduce(into: [:]) { partialResult, element in
                        let (storageId, transactionParams) = element
                        partialResult[storageId] = transactionParams
                    }
                }

                inMemoryStorage.mutate { storage in
                    storage.merge(storedTransactionParams, uniquingKeysWith: { old, _ in old })
                }

                return cardTokens
            }
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .handleEvents(receiveOutput: { walletManager, loadedCardTokens in
                walletManager.lastLoadedCardTokens = loadedCardTokens
            })
            .mapToVoid()
            .eraseToAnyPublisher()
    }

    private func getIncompleteTokenTransaction(for asset: Asset) -> KaspaKRC20.IncompleteTokenTransactionParams? {
        switch asset {
        case .coin, .reserve, .feeResource:
            return nil
        case .token(let token):
            return incompleteTokenTransactionsInMemoryStorage[token.asStorageId]
        }
    }

    private func store(incompleteTokenTransaction: KaspaKRC20.IncompleteTokenTransactionParams, for token: Token) async {
        let storageId = token.asStorageId
        incompleteTokenTransactionsInMemoryStorage.mutate { $0[storageId] = incompleteTokenTransaction }
        await dataStorage.store(key: storageId.id, value: incompleteTokenTransaction)
    }

    private func removeIncompleteTokenTransaction(for token: Token) async {
        let storageId = token.asStorageId
        incompleteTokenTransactionsInMemoryStorage.mutate { $0[storageId] = nil }
        await dataStorage.store(key: storageId.id, value: nil as KaspaKRC20.IncompleteTokenTransactionParams?)
    }

    private func makeTransaction(
        from incompleteTokenTransactionParams: KaspaKRC20.IncompleteTokenTransactionParams,
        for token: Token
    ) -> Transaction? {
        guard let tokenValue = Decimal(stringValue: incompleteTokenTransactionParams.envelope.amt) else {
            return nil
        }

        let transactionAmount = tokenValue / token.decimalValue
        let fee = Decimal(incompleteTokenTransactionParams.targetOutputAmount) / wallet.blockchain.decimalValue - dustValue.value
        let feeAmount = Amount(with: wallet.blockchain, value: fee)

        return Transaction(
            amount: .init(
                with: wallet.blockchain,
                type: .token(value: token),
                value: transactionAmount
            ),
            fee: .init(feeAmount, parameters: KaspaKRC20.RevealTransactionFeeParameter(amount: feeAmount)),
            sourceAddress: defaultSourceAddress,
            destinationAddress: incompleteTokenTransactionParams.envelope.to,
            changeAddress: defaultSourceAddress,
            params: incompleteTokenTransactionParams
        )
    }
}

extension KaspaWalletManager: DustRestrictable {
    var dustValue: Amount {
        Amount(with: wallet.blockchain, value: Decimal(0.2))
    }
}

extension KaspaWalletManager: WithdrawalNotificationProvider {
    // Chia, kaspa have the same logic
    @available(*, deprecated, message: "Use MaximumAmountRestrictable")
    func validateWithdrawalWarning(amount: Amount, fee: Amount) -> WithdrawalWarning? {
        let amountAvailableToSend = txBuilder.availableAmount() - fee
        if amount <= amountAvailableToSend {
            return nil
        }

        let amountToReduceBy = amount - amountAvailableToSend

        return WithdrawalWarning(
            warningMessage: Localization.commonUtxoValidateWithdrawalMessageWarning(
                wallet.blockchain.displayName,
                txBuilder.maxInputCount,
                amountAvailableToSend.description
            ),
            reduceMessage: Localization.commonOk,
            suggestedReduceAmount: amountToReduceBy
        )
    }

    func withdrawalNotification(amount: Amount, fee: Fee) -> WithdrawalNotification? {
        // The 'Mandatory amount change' withdrawal suggestion has been superseded by a validation performed in
        // the 'MaximumAmountRestrictable.validateMaximumAmount(amount:fee:)' method below
        return nil
    }
}

extension KaspaWalletManager: MaximumAmountRestrictable {
    func validateMaximumAmount(amount: Amount, fee: Amount) throws {
        switch amount.type {
        case .token:
            let amountAvailableToSend = txBuilder.availableAmount()

            if fee <= amountAvailableToSend {
                return
            }

            throw ValidationError.maximumUTXO(
                blockchainName: wallet.blockchain.displayName,
                newAmount: amountAvailableToSend,
                maxUtxo: txBuilder.maxInputCount
            )

        default:
            let amountAvailableToSend = txBuilder.availableAmount() - fee

            if amount <= amountAvailableToSend {
                return
            }

            throw ValidationError.maximumUTXO(
                blockchainName: wallet.blockchain.displayName,
                newAmount: amountAvailableToSend,
                maxUtxo: txBuilder.maxInputCount
            )
        }
    }
}

// MARK: - AssetRequirementsManager protocol conformance

extension KaspaWalletManager: AssetRequirementsManager {
    func requirementsCondition(for asset: Asset) -> AssetRequirementsCondition? {
        guard
            let token = asset.token,
            let incompleteTokenTransaction = getIncompleteTokenTransaction(for: asset)
        else {
            return nil
        }

        return .paidTransactionWithFee(
            blockchain: wallet.blockchain,
            transactionAmount: .init(with: token, value: incompleteTokenTransaction.amount),
            feeAmount: nil
        )
    }

    func fulfillRequirements(for asset: Asset, signer: any TransactionSigner) -> AnyPublisher<Void, Error> {
        return sendIncompleteKaspaTokenTransactionIfPossible(
            for: asset,
            signer: signer,
            validator: { _ in true }
        )
        .mapError { $0 }
        .mapToVoid()
        .eraseToAnyPublisher()
    }

    func discardRequirements(for asset: Asset) {
        guard let token = asset.token else {
            return
        }

        runTask(in: self) { walletManager in
            await walletManager.removeIncompleteTokenTransaction(for: token)
        }
    }
}

// MARK: - Convenience extensions

private extension Token {
    var asStorageId: KaspaIncompleteTokenTransactionStorageID { .init(contract: contractAddress) }
}
