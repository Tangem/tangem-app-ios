//
//  Bitcoin.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 06.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Combine
import BitcoinCore

class BitcoinWalletManager: BaseManager, WalletManager, DustRestrictable {
    var allowsFeeSelection: Bool { true }
    var txBuilder: BitcoinTransactionBuilder!
    var networkService: BitcoinNetworkProvider!
    
    /*
     The current default minimum relay fee is 1 sat/vbyte.
     https://learnmeabitcoin.com/technical/transaction/fee/#:~:text=The%20current%20default%20minimum%20relay,mined%20in%20to%20the%20blockchain.
     */
    var minimalFeePerByte: Decimal { 1 }
    var minimalFee: Decimal { 0.00001 }
    var dustValue: Amount {
        Amount(with: wallet.blockchain, value: minimalFee)
    }
    
    var loadedUnspents: [BitcoinUnspentOutput] = []
    
    var currentHost: String { networkService.host }
    var outputsCount: Int? { loadedUnspents.count }
    
    override func update(completion: @escaping (Result<Void, Error>)-> Void) {
        cancellable = networkService.getInfo(addresses: wallet.addresses.map { $0.value })
            .eraseToAnyPublisher()
            .subscribe(on: DispatchQueue.global())
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
    
    func updateWallet(with response: [BitcoinResponse]) {
        let balance = response.reduce(into: 0) { $0 += $1.balance }
        let hasUnconfirmed = response.contains(where: { $0.hasUnconfirmed })
        let unspents = response.flatMap { $0.unspentOutputs }
        
        wallet.add(coinValue: balance)
        loadedUnspents = unspents
        txBuilder.unspentOutputs = unspents
        
        wallet.clearPendingTransaction()
        if hasUnconfirmed {
            response
                .flatMap { $0.pendingTxRefs }
                .forEach {
                    let mapper = PendingTransactionRecordMapper()
                    let transaction = mapper.mapToPendingTransactionRecord($0, blockchain: wallet.blockchain)
                    wallet.addPendingTransaction(transaction)
                }
        }
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        return networkService.getFee()
            .tryMap { [weak self] response throws -> [Fee] in
                guard let self = self else { throw WalletError.empty }
                
                return self.processFee(response, amount: amount, destination: destination)
            }
            .eraseToAnyPublisher()
    }
    
    private func send(_ transaction: Transaction, signer: TransactionSigner, sequence: Int, isPushingTx: Bool) -> AnyPublisher<TransactionSendResult, SendTxError> {
        guard let hashes = txBuilder.buildForSign(transaction: transaction, sequence: sequence) else {
            return .sendTxFail(error: SendTxError(error: WalletError.failedToBuildTx))
        }
        
        return signer.sign(hashes: hashes,
                           walletPublicKey: self.wallet.publicKey)
            .tryMap {[weak self] signatures -> (String) in
                guard let self = self else { throw WalletError.empty }
                
                guard let tx = self.txBuilder.buildForSend(transaction: transaction, signatures: signatures, sequence: sequence) else {
                    throw WalletError.failedToBuildTx
                }
                
                return tx.hexString.lowercased()
            }
            .flatMap {[weak self] tx -> AnyPublisher<TransactionSendResult, Error> in
                guard let self else { return .emptyFail }
                
                let txHashPublisher: AnyPublisher<String, Error>
                
                if isPushingTx {
                    txHashPublisher = self.networkService
                        .push(transaction: tx)
                        .eraseToAnyPublisher()
                } else {
                    txHashPublisher = self.networkService
                        .send(transaction: tx)
                        .eraseToAnyPublisher()
                }
                
                return txHashPublisher.tryMap {[weak self] hash in
                    guard let self = self else { throw WalletError.empty }
                    
                    let mapper = PendingTransactionRecordMapper()
                    let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: hash)
                    self.wallet.addPendingTransaction(record)
                    return TransactionSendResult(hash: hash)
                }
                .mapSendError(tx: tx)
                .eraseToAnyPublisher()
            }
            .eraseSendError()
            .eraseToAnyPublisher()
    }
    
    func processFee(_ response: BitcoinFee, amount: Amount, destination: String) -> [Fee] {
        // Don't remove `.rounded` from here, intValue can sometimes go crazy
        // e.g. with the Decimal of (662701 / 3), producing 0 integer
        var minRate = (max(response.minimalSatoshiPerByte, minimalFeePerByte).rounded(roundingMode: .up) as NSDecimalNumber).intValue
        var normalRate = (max(response.normalSatoshiPerByte, minimalFeePerByte).rounded(roundingMode: .up) as NSDecimalNumber).intValue
        var maxRate = (max(response.prioritySatoshiPerByte, minimalFeePerByte).rounded(roundingMode: .up) as NSDecimalNumber).intValue
        
        var minFee = txBuilder.bitcoinManager.fee(for: amount.value, address: destination, feeRate: minRate, senderPay: false, changeScript: nil, sequence: .max)
        var normalFee = txBuilder.bitcoinManager.fee(for: amount.value, address: destination, feeRate: normalRate, senderPay: false, changeScript: nil, sequence: .max)
        var maxFee = txBuilder.bitcoinManager.fee(for: amount.value, address: destination, feeRate: maxRate, senderPay: false, changeScript: nil, sequence: .max)
        
        
        let minimalFeeRate = (((minimalFee * Decimal(minRate)) / minFee).rounded(scale: 0, roundingMode: .up) as NSDecimalNumber).intValue
        let minimalFee = txBuilder.bitcoinManager.fee(for: amount.value, address: destination, feeRate: minimalFeeRate, senderPay: false, changeScript: nil, sequence: .max)
        if minFee < minimalFee {
            minRate = minimalFeeRate
            minFee = minimalFee
        }
        
        if normalFee < minimalFee {
            normalRate = minimalFeeRate
            normalFee = minimalFee
        }
        
        if maxFee < minimalFee {
            maxRate = minimalFeeRate
            maxFee = minimalFee
        }

        return [
            Fee(Amount(with: wallet.blockchain, value: minFee), parameters: BitcoinFeeParameters(rate: minRate)),
            Fee(Amount(with: wallet.blockchain, value: normalFee), parameters: BitcoinFeeParameters(rate: normalRate)),
            Fee(Amount(with: wallet.blockchain, value: maxFee), parameters: BitcoinFeeParameters(rate: maxRate)),
        ]
    }
}

@available(iOS 13.0, *)
extension BitcoinWalletManager: BitcoinTransactionFeeCalculator {
    func calculateFee(satoshiPerByte: Int, amount: Amount, destination: String) -> Fee {
        let fee = txBuilder.bitcoinManager.fee(
            for: amount.value,
            address: destination,
            feeRate: satoshiPerByte,
            senderPay: false,
            changeScript: nil,
            sequence: .max
        )
        return Fee(Amount(with: wallet.blockchain, value: fee), parameters: BitcoinFeeParameters(rate: satoshiPerByte))
    }
}

@available(iOS 13.0, *)
extension BitcoinWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        txBuilder.unspentOutputs = loadedUnspents
        return send(transaction, signer: signer, sequence: SequenceValues.default.rawValue, isPushingTx: false)
    }
}

extension BitcoinWalletManager: TransactionPusher {
    func isPushAvailable(for transactionHash: String) -> Bool {
        guard networkService.supportsTransactionPush else {
            return false
        }
        
        guard let tx = wallet.pendingTransactions.first(where: { $0.hash == transactionHash }) else {
            return false
        }
        
        let userAddresses = wallet.addresses.map { $0.value }
        
        guard userAddresses.contains(tx.source) else {
            return false
        }
        
        guard let params = tx.transactionParams as? BitcoinTransactionParams else {
            return false
        }
        
        var containNotRbfInput: Bool = false
        var containOtherOutputAccount: Bool = false
        params.inputs.forEach {
            if !userAddresses.contains($0.address) {
                containOtherOutputAccount = true
            }
            if $0.sequence >= SequenceValues.disabledReplacedByFee.rawValue {
                containNotRbfInput = true
            }
        }
        
        return !containNotRbfInput && !containOtherOutputAccount
    }
    
    func getPushFee(for transactionHash: String) -> AnyPublisher<[Fee], Error> {
        guard let tx = wallet.pendingTransactions.first(where: { $0.hash == transactionHash }) else {
            return .anyFail(error: BlockchainSdkError.failedToFindTransaction)
        }
        
        txBuilder.unspentOutputs = loadedUnspents.filter { $0.transactionHash != transactionHash }
        
        return getFee(amount: tx.amount, destination: tx.destination)
            .map { [weak self] feeDataModel in
                self?.txBuilder.unspentOutputs = self?.loadedUnspents
                return feeDataModel
            }
            .eraseToAnyPublisher()
    }
    
    func pushTransaction(with transactionHash: String, newTransaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Void, SendTxError> {
        guard let oldTx = wallet.pendingTransactions.first(where: { $0.hash == transactionHash }) else {
            return .sendTxFail(error: BlockchainSdkError.failedToFindTransaction)
        }
        
        guard oldTx.fee.amount.value < newTransaction.fee.amount.value else {
            return .sendTxFail(error: BlockchainSdkError.feeForPushTxNotEnough)
        }
        
        guard
            let params = oldTx.transactionParams as? BitcoinTransactionParams,
            let sequence = params.inputs.max(by: { $0.sequence < $1.sequence })?.sequence
        else {
            return .sendTxFail(error: BlockchainSdkError.failedToFindTxInputs)
        }
        
        //        let outputs = loadedUnspents.filter { unspent in params.inputs.contains(where: { $0.prevHash == unspent.transactionHash })}
        let outputs = loadedUnspents.filter { $0.transactionHash != transactionHash }
        txBuilder.unspentOutputs = outputs
        
        return send(newTransaction, signer: signer, sequence: sequence + 1, isPushingTx: true)
            .mapToVoid()
            .eraseToAnyPublisher()
    }
}

extension BitcoinWalletManager: SignatureCountValidator {
    func validateSignatureCount(signedHashes: Int) -> AnyPublisher<Void, Error> {
        networkService.getSignatureCount(address: wallet.address)
            .tryMap {
                if signedHashes != $0 { throw BlockchainSdkError.signatureCountNotMatched }
            }
            .eraseToAnyPublisher()
    }
}

extension BitcoinWalletManager: ThenProcessable { }
