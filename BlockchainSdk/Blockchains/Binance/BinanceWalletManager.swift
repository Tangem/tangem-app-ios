//
//  BinanceWalletManager.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 15.02.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BinanceChain
import struct TangemSdk.SignResponse

class BinanceWalletManager: BaseManager, WalletManager {
    var txBuilder: BinanceTransactionBuilder!
    var networkService: BinanceNetworkService!
    private var latestTxDate: Date?
    
    var currentHost: String { networkService.host }
    
    override func update(completion: @escaping (Result<Void, Error>)-> Void) {
        cancellable = networkService
            .getInfo(address: wallet.address)
            .sink(receiveCompletion: { [weak self] completionSubscription in
                if case let .failure(error) = completionSubscription {
                    self?.wallet.clearAmounts()
                    completion(.failure(error))
                }
            }, receiveValue: { [weak self] response in
                self?.updateWallet(with: response)
                completion(.success(()))
            })
    }
    
    private func updateWallet(with response: BinanceInfoResponse) {
        let blockchain = wallet.blockchain
        let coinBalance = response.balances[blockchain.currencySymbol] ?? 0 //if withdrawal all funds, there is no balance from network
        wallet.add(coinValue: coinBalance)
        
        cardTokens.forEach { token in
            let balance = response.balances[token.contractAddress] ?? 0 //if withdrawal all funds, there is no balance from network
            wallet.add(tokenValue: balance, for: token)
        }
        
        txBuilder.binanceWallet.sequence = response.sequence
        txBuilder.binanceWallet.accountNumber = response.accountNumber
        // We believe that a transaction will be confirmed within 10 seconds
        let date = Date(timeIntervalSinceNow: -10)
        wallet.removePendingTransaction(older: date)
    }
}

// MARK: - TransactionSender

extension BinanceWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        guard let msg = txBuilder.buildForSign(transaction: transaction) else {
            return .sendTxFail(error: WalletError.failedToBuildTx)
        }
        
        let hash = msg.encodeForSignature()
        return signer.sign(hash: hash, walletPublicKey: self.wallet.publicKey)
            .tryMap {[weak self] signature -> Message in
                guard let self = self else { throw WalletError.empty }
                
                guard let tx = self.txBuilder.buildForSend(signature: signature, hash: hash) else {
                    throw WalletError.failedToBuildTx
                }
                return tx
            }
            .flatMap {[weak self] tx -> AnyPublisher<TransactionSendResult, Error> in
                self?.networkService.send(transaction: tx).tryMap { [weak self] response in
                    guard let self = self else { throw WalletError.empty }
                    let hash = response.broadcast.first?.hash ?? response.tx.txHash
                    let mapper = PendingTransactionRecordMapper()
                    let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: hash)
                    self.wallet.addPendingTransaction(record)
                    self.latestTxDate = Date()
                    return TransactionSendResult(hash: hash)

                    }
                    .mapSendError(tx: tx.encodeForSignature().hexString.lowercased())
                    .eraseToAnyPublisher() ?? .emptyFail
            }
            .eraseSendError()
            .eraseToAnyPublisher()
    }
}

// MARK: - ThenProcessable

extension BinanceWalletManager: ThenProcessable { }

// MARK: - TransactionFeeProvider

extension BinanceWalletManager: TransactionFeeProvider {
    var allowsFeeSelection: Bool { false }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        return networkService.getFee()
            .tryMap { [weak self] feeString throws -> [Fee] in
                guard let self = self else { throw WalletError.empty }
                
                guard let feeValue = Decimal(feeString) else {
                    throw WalletError.failedToGetFee
                }
                
                let feeAmount = Amount(with: self.wallet.blockchain, value: feeValue)
                return [Fee(feeAmount)]
            }
            .eraseToAnyPublisher()
    }
}
