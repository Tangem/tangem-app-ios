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
    private let txBuilder: TONTransactionBuilder
    private var isAvailable: Bool = true
    private var jettonWalletAddressCache: [Token: String] = [:]
    
    // MARK: - Init
    
    init(wallet: Wallet, networkService: TONNetworkService) throws {
        self.networkService = networkService
        self.txBuilder = .init(wallet: wallet)
        super.init(wallet: wallet)
    }
    
    // MARK: - Implementation
    
    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        cancellable = networkService
            .getInfo(address: wallet.address, tokens: cardTokens)
            .sink(
                receiveCompletion: { [weak self] completionSubscription in
                    if case let .failure(error) = completionSubscription {
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
        getJettonWalletAddressIfNeeded(for: transaction.sourceAddress,transactionType: transaction.amount.type)
            .receive(on: DispatchQueue.global())
            .tryMap { [weak self] jettonWalletAddress -> String in
                guard let self else {
                    throw WalletError.failedToBuildTx
                }
                
                let params = transaction.params as? TONTransactionParams
                
                let input = try self.txBuilder.buildForSign(
                    amount: transaction.amount,
                    destination: transaction.destinationAddress,
                    jettonWalletAddress: jettonWalletAddress,
                    params: params
                )
                return try self.buildTransaction(input: input, with: signer)
            }
            .flatMap { [weak self] message -> AnyPublisher<String, Error> in
                guard let self else {
                    return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
                }
                
                return self.networkService
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

    func buildTransaction(input: TheOpenNetworkSigningInput, with signer: TransactionSigner? = nil) throws -> String {
        let output: TheOpenNetworkSigningOutput
        
        if let signer = signer {
            guard let publicKey = PublicKey(tangemPublicKey: self.wallet.publicKey.blockchainKey, publicKeyType: CoinType.ton.publicKeyType) else {
                throw WalletError.failedToBuildTx
            }
            
            let coreSigner = WalletCoreSigner(
                sdkSigner: signer,
                blockchainKey: publicKey.data,
                walletPublicKey: self.wallet.publicKey,
                curve: wallet.blockchain.curve
            )
            output = try AnySigner.signExternally(input: input, coin: .ton, signer: coreSigner)
        } else {
            output = AnySigner.sign(input: input, coin: .ton)
        }
        
        return try self.txBuilder.buildForSend(output: output)
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
                
                let input = try self.txBuilder.buildForSign(
                    amount: amount,
                    destination: destination,
                    jettonWalletAddress: jettonWalletAddress
                )
                return try self.buildTransaction(input: input)
            }
            .flatMap { [weak self] message -> AnyPublisher<[Fee], Error> in
                guard let self else {
                    return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
                }
                
                return self.networkService.getFee(address: self.wallet.address, message: message)
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
        if info.sequenceNumber != txBuilder.sequenceNumber {
            wallet.clearPendingTransaction()
        }
        
        wallet.add(coinValue: info.balance)
        
        for (token, tokenInfo) in info.tokensInfo {
            wallet.add(tokenValue: tokenInfo.balance, for: token)
            
            // jetton wallet address is used to calculate fee and build transaction
            jettonWalletAddressCache[token] = tokenInfo.jettonWalletAddress
        }
        
        txBuilder.sequenceNumber = info.sequenceNumber
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
}
