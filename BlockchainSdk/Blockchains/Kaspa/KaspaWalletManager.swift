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
    private let txBuilder: KaspaTransactionBuilder
    private let networkService: KaspaNetworkService
    private let networkServiceKRC20: KaspaNetworkServiceKRC20
    private let dataStorage: BlockchainDataStorage

    @available(*, deprecated, message: "Test only")
    private var testInMemoryStorage: ThreadSafeContainer<
        [KaspaIncompleteTokenTransactionStorageID: KaspaKRC20.IncompleteTokenTransactionParams]
    > = [:]

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

        cancellable = Publishers.Zip(
            networkService.getInfo(address: wallet.address, unconfirmedTransactionHashes: unconfirmedTransactionHashes),
            networkServiceKRC20.balance(address: wallet.address, tokens: cardTokens)
        )
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

    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        switch transaction.amount.type {
        case .token(value: let token):
            switch transaction.params {
            case is KaspaKRC20.IncompleteTokenTransactionParams:
                return sendKaspaRevealTokenTransaction(transaction, token: token, signer: signer)
            default:
                return sendKaspaTokenTransaction(transaction, token: token, signer: signer)
            }

        default:
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

                return commitTx
            }
            .withWeakCaptureOf(self)
            .flatMap { manager, commitTx in
                // Send Commit
                let encodedRawTransactionData = try? JSONEncoder().encode(commitTx)

                return manager.networkService
                    .send(transaction: KaspaTransactionRequest(transaction: commitTx))
                    .mapSendError(tx: encodedRawTransactionData?.hexString.lowercased())
                    .eraseToAnyPublisher()
            }
            .withWeakCaptureOf(self)
            .asyncMap { manager, response in
                // Store Commit
                await manager.store(incompleteTokenTransaction: meta.incompleteTransactionParams, for: token)
                return response
            }
            .handleEvents(receiveOutput: { [weak self] response in
                let mapper = PendingTransactionRecordMapper()
                let commitTransactionId = response.transactionId
                let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: commitTransactionId)
                self?.wallet.addPendingTransaction(record)
                self?.scheduleRevealTransactionSending(builtKaspaRevealTx, forCommitTransactionWithId: commitTransactionId, token: token)
            })
            .map { response in
                return TransactionSendResult(hash: response.transactionId)
            }
            .eraseSendError()
            .eraseToAnyPublisher()
    }

    /// Used to send reveal transaction for the first time after successful commit transaction.
    /// - Note: Successful KRC20 reveal transaction won't add pending transaction to the wallet.
    private func scheduleRevealTransactionSending(
        _ revealTransaction: KaspaTransactionData?,
        forCommitTransactionWithId commitTransactionId: String,
        token: Token
    ) {
        var cancellable: AnyCancellable?

        cancellable = Deferred {
            Future { promise in
                if let revealTransaction {
                    promise(.success(revealTransaction))
                } else {
                    promise(.failure(KaspaKRC20.Error.unableToSendRevealTransaction))
                }
            }
        }
        .delay(for: .seconds(2), scheduler: DispatchQueue.main)
        .withWeakCaptureOf(self)
        .flatMap { walletManager, revealTransaction in
            let encodedRawTransactionData = try? JSONEncoder().encode(revealTransaction)

            return walletManager.networkService
                .send(transaction: KaspaTransactionRequest(transaction: revealTransaction))
                .mapSendError(tx: encodedRawTransactionData?.hexString.lowercased())
        }
        .withWeakCaptureOf(self)
        .asyncMap { manager, response in
            // Delete Commit on success
            await manager.removeIncompleteTokenTransaction(for: token)
            return response.transactionId
        }
        .receiveCompletion { [weak self] _ in
            // Both successful and failed KRC20 reveal transactions remove the pending transaction for the KRC20 commit transaction
            self?.removePendingTransactions(withHashes: [commitTransactionId])
            withExtendedLifetime(cancellable) {}
        }
    }

    /// Used to retry a previously failed reveal transaction.
    /// - Note: Successful KRC20 reveal transaction won't add pending transaction to the wallet.
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

        removePendingTransactions(withHashes: info.confirmedTransactionHashes)
    }

    private func removePendingTransactions(withHashes pendingTransactionHashes: [String]) {
        wallet.removePendingTransaction { hash in
            pendingTransactionHashes.contains(hash)
        }
    }

    // MARK: - KRC20 Tokens management

    private func getIncompleteTokenTransaction(for asset: Asset) -> KaspaKRC20.IncompleteTokenTransactionParams? {
        switch asset {
        case .coin, .reserve, .feeResource:
            return nil
        case .token(let token):
            return testInMemoryStorage[token.asStorageId]
        }
    }

    private func store(incompleteTokenTransaction: KaspaKRC20.IncompleteTokenTransactionParams, for token: Token) async {
        let storageId = token.asStorageId
        testInMemoryStorage.mutate { $0[storageId] = incompleteTokenTransaction }
        await dataStorage.store(key: storageId.id, value: incompleteTokenTransaction)
    }

    private func removeIncompleteTokenTransaction(for token: Token) async {
        let storageId = token.asStorageId
        testInMemoryStorage.mutate { $0[storageId] = nil }
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
                    let tokenTransaction = walletManager.makeTransaction(from: incompleteTokenTransaction, for: token)
                else {
                    throw KaspaKRC20.Error.unableToBuildRevealTransaction
                }

                return tokenTransaction
            }
            .withWeakCaptureOf(self)
            .flatMap { walletManager, tokenTransaction in
                return walletManager
                    .send(tokenTransaction, signer: signer)
                    .mapError { $0 }
            }
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
