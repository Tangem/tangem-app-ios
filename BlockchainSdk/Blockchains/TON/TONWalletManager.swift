//
//  TONWalletManager.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 12.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import WalletCore

final class TONWalletManager: BaseManager, WalletManager {
    // MARK: - Properties

    var currentHost: String { networkService.host }

    // MARK: - Private Properties

    private let networkService: TONNetworkService
    private let transactionBuilder: TONTransactionBuilder
    private var isAvailable: Bool = true
    private var jettonWalletAddressCache: [Token: String] = [:]

    // MARK: - Init

    init(wallet: Wallet, transactionBuilder: TONTransactionBuilder, networkService: TONNetworkService) throws {
        self.networkService = networkService
        self.transactionBuilder = transactionBuilder
        super.init(wallet: wallet)
    }

    // MARK: - Implementation

    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        cancellable = networkService
            .getInfo(address: wallet.address, tokens: cardTokens)
            .sink(
                receiveCompletion: { [weak self] completionSubscription in
                    if case .failure(let error) = completionSubscription {
                        self?.wallet.clearAmounts()
                        self?.isAvailable = false
                        completion(.failure(error))
                    }
                },
                receiveValue: { [weak self] info in
                    self?.update(with: info, completion: completion)
                }
            )
    }

    func send(
        _ transaction: Transaction,
        signer: TransactionSigner
    ) -> AnyPublisher<TransactionSendResult, SendTxError> {
        getJettonWalletAddressIfNeeded(for: transaction.sourceAddress, transactionType: transaction.amount.type)
            .receive(on: DispatchQueue.global())
            .tryMap { [weak self] jettonWalletAddress -> (TONTransactionInput, Data) in
                guard let self else {
                    throw WalletError.failedToBuildTx
                }

                let params = transaction.params as? TONTransactionParams

                let buildInput = TONTransactionInput(
                    amount: transaction.amount,
                    destination: transaction.destinationAddress,
                    expireAt: createExpirationTimestampSecs(),
                    jettonWalletAddress: jettonWalletAddress,
                    params: params
                )

                let hashForSign = try transactionBuilder.buildForSign(buildInput: buildInput)

                return (buildInput, hashForSign.data)
            }
            .withWeakCaptureOf(self)
            .flatMap { manager, input in
                let (buildInput, hash) = input
                let transactionInputPublisher = Just(buildInput).setFailureType(to: Error.self)
                let signaturePublisher = signer.sign(hash: hash, walletPublicKey: manager.wallet.publicKey)

                return Publishers.Zip(signaturePublisher, transactionInputPublisher)
            }
            .withWeakCaptureOf(self)
            .tryMap { walletManager, input -> String in
                let (signature, buildInput) = input

                let dataForSend = try walletManager.transactionBuilder.buildForSend(
                    buildInput: buildInput,
                    signature: signature
                )

                return dataForSend
            }
            .flatMap { [weak self] message -> AnyPublisher<String, Error> in
                guard let self else {
                    return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
                }

                return networkService
                    .send(message: message)
                    .mapSendError(tx: message)
                    .eraseToAnyPublisher()
            }
            .map { [weak self] hash in
                let mapper = PendingTransactionRecordMapper()
                let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: hash)
                self?.wallet.addPendingTransaction(record)
                return TransactionSendResult(hash: hash)
            }
            .eraseSendError()
            .eraseToAnyPublisher()
    }
}

// MARK: - TransactionFeeProvider

extension TONWalletManager: TransactionFeeProvider {
    var allowsFeeSelection: Bool { false }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        getJettonWalletAddressIfNeeded(transactionType: amount.type)
            .tryMap { [weak self] jettonWalletAddress -> String in
                guard let self else {
                    throw WalletError.failedToBuildTx
                }

                let buildInput = TONTransactionInput(
                    amount: amount,
                    destination: destination,
                    expireAt: createExpirationTimestampSecs(),
                    jettonWalletAddress: jettonWalletAddress,
                    params: nil
                )

                let buildForSend = try transactionBuilder.buildForSend(
                    buildInput: buildInput,
                    signature: Data(repeating: 0, count: 64)
                )

                return buildForSend
            }
            .flatMap { [weak self] message -> AnyPublisher<[Fee], Error> in
                guard let self else {
                    return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
                }

                return networkService.getFee(address: wallet.address, message: message)
                    .withWeakCaptureOf(self)
                    .map { walletManager, fees in
                        walletManager.appendJettonTransferProcessingFeeIfNeeded(fees, amountType: amount.type)
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private Implementation

private extension TONWalletManager {
    private func update(with info: TONWalletInfo, completion: @escaping (Result<Void, Error>) -> Void) {
        if info.sequenceNumber != transactionBuilder.sequenceNumber {
            wallet.clearPendingTransaction()
        }

        wallet.add(coinValue: info.balance)

        for (token, tokenInfo) in info.tokensInfo {
            switch tokenInfo {
            case .success(let value):
                wallet.add(tokenValue: value.balance, for: token)
                // jetton wallet address is used to calculate fee and build transaction
                jettonWalletAddressCache[token] = value.jettonWalletAddress
            case .failure:
                wallet.clearAmount(for: token)
                jettonWalletAddressCache[token] = nil
            }
        }

        transactionBuilder.sequenceNumber = info.sequenceNumber
        isAvailable = info.isAvailable
        completion(.success(()))
    }

    private func getJettonWalletAddressIfNeeded(
        for ownerAddress: String? = nil,
        transactionType: Amount.AmountType
    ) -> AnyPublisher<String?, Error> {
        let ownerAddress = ownerAddress ?? defaultSourceAddress
        switch transactionType {
        case .coin, .reserve, .feeResource:
            return .justWithError(output: nil)
        case .token(let token):
            guard let cachedJettonWalletAddress = jettonWalletAddressCache[token] else {
                return networkService.getJettonWalletAddress(for: ownerAddress, token: token)
                    .map { .some($0) }
                    .eraseToAnyPublisher()
            }
            return .justWithError(output: cachedJettonWalletAddress)
        }
    }

    private func appendJettonTransferProcessingFeeIfNeeded(_ fees: [Fee], amountType: Amount.AmountType) -> [Fee] {
        guard case .token = amountType else {
            return fees
        }
        return fees.map { fee in
            var amount = fee.amount
            amount.value += TONTransactionBuilder.Constants.jettonTransferProcessingFee
            return Fee(amount, parameters: fee.parameters)
        }
    }

    private func createExpirationTimestampSecs() -> UInt32 {
        UInt32(Date().addingTimeInterval(TimeInterval(Constants.transactionLifetimeInMin * 60)).timeIntervalSince1970)
    }
}

private extension TONWalletManager {
    enum Constants {
        static let transactionLifetimeInMin: Double = 1
    }
}
