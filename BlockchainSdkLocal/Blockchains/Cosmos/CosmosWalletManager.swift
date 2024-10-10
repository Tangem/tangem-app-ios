//
//  CosmosWalletManager.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 11.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import WalletCore
import TangemSdk

class CosmosWalletManager: BaseManager, WalletManager {
    var currentHost: String { networkService.host }
    var allowsFeeSelection: Bool { cosmosChain.allowsFeeSelection }
    
    var networkService: CosmosNetworkService!
    var txBuilder: CosmosTransactionBuilder!
    
    private let cosmosChain: CosmosChain
    
    init(cosmosChain: CosmosChain, wallet: Wallet) {
        self.cosmosChain = cosmosChain
        
        super.init(wallet: wallet)
    }
    
    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        let transactionHashes = wallet.pendingTransactions.map { $0.hash }
        
        cancellable = networkService
            .accountInfo(for: wallet.address, tokens: cardTokens, transactionHashes: transactionHashes)
            .sink { [weak self] result in
                switch result {
                case .failure(let error):
                    self?.wallet.clearAmounts()
                    completion(.failure(error))
                case .finished:
                    completion(.success(()))
                }
            } receiveValue: { [weak self] in
                self?.updateWallet(accountInfo: $0)
            }
    }

    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        Result {
            try txBuilder.buildForSign(transaction: transaction)
        }
        .publisher
        .withWeakCaptureOf(self)
        .flatMap { manager, hash in
            signer
                .sign(hash: hash, walletPublicKey: self.wallet.publicKey)
                .tryMap { signature -> Data in
                    let signature = try Secp256k1Signature(with: signature)
                    return try signature.unmarshal(with: manager.wallet.publicKey.blockchainKey, hash: hash).data
                }
        }
        .withWeakCaptureOf(self)
        .tryMap { manager, signature -> Data in
            try manager.txBuilder.buildForSend(transaction: transaction, signature: signature)
        }
        .withWeakCaptureOf(self)
        .flatMap { manager, transaction in
            manager.networkService
                .send(transaction: transaction)
                .mapSendError(tx: transaction.hexString.lowercased())
        }
        .handleEvents(receiveOutput: { [weak self] hash in
            let mapper = PendingTransactionRecordMapper()
            let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: hash)
            self?.wallet.addPendingTransaction(record)
        })
        .map { TransactionSendResult(hash: $0) }
        .eraseSendError()
        .eraseToAnyPublisher()
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        return estimateGas(amount: amount, destination: destination)
            .tryMap { [weak self] gas in
                guard let self = self else { throw WalletError.empty }
                
                let blockchain = self.cosmosChain.blockchain
                let gasPrices = self.cosmosChain.gasPrices(for: amount.type)
                
                return try Array(repeating: gas, count: gasPrices.count)
                    .enumerated()
                    .map { index, estimatedGas in
                        let gasMultiplier = self.cosmosChain.gasMultiplier
                        let feeMultiplier = self.cosmosChain.feeMultiplier
                        
                        let gas = estimatedGas * gasMultiplier
                        
                        var feeValueInSmallestDenomination = UInt64(Double(gas) * gasPrices[index] * feeMultiplier)
                        if let tax = self.tax(for: amount) {
                            feeValueInSmallestDenomination += tax
                        }
                        
                        let feeDecimalValue: Decimal
                        let feeAmountType: Amount.AmountType
                        switch blockchain.feePaidCurrency {
                        case .sameCurrency:
                            feeDecimalValue = amount.type.token?.decimalValue ?? blockchain.decimalValue
                            feeAmountType = amount.type
                        case .coin:
                            feeDecimalValue = blockchain.decimalValue
                            feeAmountType = .coin
                        case .token(let token):
                            feeDecimalValue = token.decimalValue
                            feeAmountType = .token(value: token)
                        case .feeResource:
                            throw BlockchainSdkError.notImplemented
                        }
                        
                        var feeValue = (Decimal(feeValueInSmallestDenomination) / feeDecimalValue)
                        if let extraFee = self.cosmosChain.extraFee(for: amount.value) {
                            feeValue += extraFee
                        }
                        
                        feeValue = feeValue.rounded(blockchain: blockchain)
                        
                        let parameters = CosmosFeeParameters(gas: gas)
                        return Fee(Amount(with: blockchain, type: feeAmountType, value: feeValue), parameters: parameters)
                    }
            }
            .eraseToAnyPublisher()
    }
    
    private func estimateGas(amount: Amount, destination: String) -> AnyPublisher<UInt64, Error> {
        return Just(())
            .setFailureType(to: Error.self)
            .tryMap { [weak self] Void -> Data in
                guard let self else { throw WalletError.empty }
                
                let dummyFee = Fee(
                    Amount(with: amount, value: 0),
                    parameters: CosmosFeeParameters(gas: 0)
                )

                let transaction = Transaction(
                    amount: amount,
                    fee: dummyFee,
                    sourceAddress: self.wallet.address,
                    destinationAddress: destination,
                    changeAddress: self.wallet.address
                )

                return try self.txBuilder.buildForSend(
                    transaction: transaction,
                    signature: Data(repeating: 1, count: 65) // Dummy signature
                )
            }
            .tryCatch { _ -> AnyPublisher<Data, Error> in
                .anyFail(error: WalletError.failedToGetFee)
            }
            .flatMap { [weak self] transaction -> AnyPublisher<UInt64, Error> in
                guard let self else {
                    return .anyFail(error: WalletError.empty)
                }
                
                return self.networkService.estimateGas(for: transaction)
            }
            .eraseToAnyPublisher()
    }
    
    private func updateWallet(accountInfo: CosmosAccountInfo) {
        wallet.add(amount: accountInfo.amount)
        if let accountNumber = accountInfo.accountNumber {
            txBuilder.setAccountNumber(accountNumber)
        }
        txBuilder.setSequenceNumber(accountInfo.sequenceNumber)
        
        for (token, balance) in accountInfo.tokenBalances {
            wallet.add(tokenValue: balance, for: token)
        }
        
        wallet.removePendingTransaction { hash in
            accountInfo.confirmedTransactionHashes.contains(hash)
        }
    }
    
    private func tax(for amount: Amount) -> UInt64? {
        guard case .token(let token) = amount.type,
              let taxPercent = cosmosChain.taxPercentByContractAddress[token.contractAddress]
        else {
            return nil
        }
        
        let amountInSmallestDenomination = amount.value * token.decimalValue
        let taxAmount = amountInSmallestDenomination * taxPercent / 100
        
        return (taxAmount as NSDecimalNumber).uint64Value
    }
}

extension CosmosWalletManager: ThenProcessable { }

// MARK: - StakeKitTransactionSender, StakeKitTransactionSenderProvider

extension CosmosWalletManager: StakeKitTransactionSender, StakeKitTransactionSenderProvider {
    typealias RawTransaction = Data

    func prepareDataForSign(transaction: StakeKitTransaction) throws -> Data {
        try CosmosStakeKitTransactionHelper(builder: txBuilder)
            .prepareForSign(stakingTransaction: transaction)
    }

    func prepareDataForSend(transaction: StakeKitTransaction, signature: SignatureInfo) throws -> RawTransaction {
        let unmarshal = try signature.unmarshal()

        return try CosmosStakeKitTransactionHelper(builder: txBuilder)
            .buildForSend(stakingTransaction: transaction, signature: unmarshal)
    }

    func broadcast(transaction: StakeKitTransaction, rawTransaction: RawTransaction) async throws -> String {
        try await networkService.send(transaction: rawTransaction).async()
    }
}
