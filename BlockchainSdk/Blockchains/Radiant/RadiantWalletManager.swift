//
//  RadiantWalletManager.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 05.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import WalletCore

final class RadiantWalletManager: BaseManager {
    // MARK: - Private Properties

    private let transactionBuilder: RadiantTransactionBuilder
    private let networkService: RadiantNetworkService

    // MARK: - Init

    init(wallet: Wallet, transactionBuilder: RadiantTransactionBuilder, networkService: RadiantNetworkService) throws {
        self.transactionBuilder = transactionBuilder
        self.networkService = networkService
        super.init(wallet: wallet)
    }

    // MARK: - Implementation

    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        let accountInfoPublisher = networkService
            .getInfo(address: wallet.address)

        cancellable = accountInfoPublisher
            .withWeakCaptureOf(self)
            .sink(receiveCompletion: { [weak self] result in
                switch result {
                case .failure(let error):
                    self?.wallet.clearAmounts()
                    completion(.failure(error))
                case .finished:
                    completion(.success(()))
                }
            }, receiveValue: { manager, response in
                manager.updateWallet(with: response)
            })
    }
}

// MARK: - Private Implementation

private extension RadiantWalletManager {
    func updateWallet(with addressInfo: RadiantAddressInfo) {
        let coinBalanceValue = addressInfo.balance / wallet.blockchain.decimalValue

        // Reset pending transaction
        if coinBalanceValue != wallet.amounts[.coin]?.value {
            wallet.clearPendingTransaction()
        }

        wallet.add(coinValue: coinBalanceValue)
        transactionBuilder.update(utxo: addressInfo.outputs)
    }

    func sendViaCompileTransaction(
        _ transaction: Transaction,
        signer: TransactionSigner
    ) -> AnyPublisher<TransactionSendResult, SendTxError> {
        let hashesForSign: [Data]

        do {
            hashesForSign = try transactionBuilder.buildForSign(transaction: transaction)
        } catch {
            return .sendTxFail(error: error)
        }

        return signer
            .sign(hashes: hashesForSign, walletPublicKey: wallet.publicKey)
            .withWeakCaptureOf(self)
            .tryMap { walletManager, signatures in
                try walletManager.transactionBuilder.buildForSend(transaction: transaction, signatures: signatures)
            }
            .withWeakCaptureOf(self)
            .flatMap { walletManager, rawTransactionData -> AnyPublisher<String, Error> in
                return walletManager.networkService
                    .sendTransaction(data: rawTransactionData)
                    .mapSendError(tx: rawTransactionData.hexString.lowercased())
                    .eraseToAnyPublisher()
            }
            .withWeakCaptureOf(self)
            .map { walletManager, txId -> TransactionSendResult in
                let mapper = PendingTransactionRecordMapper()
                let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: txId)
                walletManager.wallet.addPendingTransaction(record)
                return TransactionSendResult(hash: txId)
            }
            .eraseSendError()
            .eraseToAnyPublisher()
    }

    func calculateFee(for estimatedFeePerKb: Decimal, for estimateSize: Int) -> Fee {
        let decimalValue = wallet.blockchain.decimalValue
        let perKbDecimalValue = (estimatedFeePerKb * decimalValue).rounded(blockchain: wallet.blockchain, roundingMode: .up)
        let decimalFeeValue = Decimal(estimateSize) / Constants.perKbRate * perKbDecimalValue
        let feeAmountValue = (decimalFeeValue / decimalValue).rounded(blockchain: wallet.blockchain, roundingMode: .up)
        let feeAmount = Amount(with: wallet.blockchain, value: feeAmountValue)

        return Fee(feeAmount)
    }
}

// MARK: - WalletManager

extension RadiantWalletManager: WalletManager {
    var currentHost: String {
        networkService.host
    }

    var allowsFeeSelection: Bool {
        true
    }

    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        sendViaCompileTransaction(transaction, signer: signer)
    }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        return networkService
            .estimatedFee()
            .withWeakCaptureOf(self)
            .tryMap { walletManager, estimatedFeeDecimalValue -> [Fee] in
                let dummyTransactionFee: Fee = .init(
                    .init(with: walletManager.wallet.blockchain, value: estimatedFeeDecimalValue.minimalSatoshiPerByte)
                )

                let dummyTransaction = Transaction(
                    amount: amount,
                    fee: dummyTransactionFee,
                    sourceAddress: walletManager.wallet.address,
                    destinationAddress: destination,
                    changeAddress: walletManager.wallet.address
                )

                let estimatedSize = try walletManager.transactionBuilder.estimateTransactionSize(transaction: dummyTransaction)

                let minimalFee = walletManager.calculateFee(for: estimatedFeeDecimalValue.minimalSatoshiPerByte, for: estimatedSize)
                let normalFee = walletManager.calculateFee(for: estimatedFeeDecimalValue.normalSatoshiPerByte, for: estimatedSize)
                let priorityFee = walletManager.calculateFee(for: estimatedFeeDecimalValue.prioritySatoshiPerByte, for: estimatedSize)

                return [
                    minimalFee,
                    normalFee,
                    priorityFee,
                ]
            }
            .eraseToAnyPublisher()
    }
}

extension RadiantWalletManager {
    enum Constants {
        /*
         - We use 1000, because Electrum node return fee for per 1000 bytes.
         */
        static let perKbRate: Decimal = 1000
    }
}
