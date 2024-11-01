//
//  CasperWalletManager.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 22.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class CasperWalletManager: BaseManager, WalletManager {
    var currentHost: String {
        networkService.host
    }

    var allowsFeeSelection: Bool {
        false
    }

    // MARK: - Private Implementation

    private let networkService: CasperNetworkService
    private let transactionBuilder: CasperTransactionBuilder

    // MARK: - Init

    init(wallet: Wallet, networkService: CasperNetworkService, transactionBuilder: CasperTransactionBuilder) {
        self.networkService = networkService
        self.transactionBuilder = transactionBuilder
        super.init(wallet: wallet)
    }

    // MARK: - Manager Implementation

    override func update(completion: @escaping (Result<Void, any Error>) -> Void) {
        let balanceInfoPublisher = networkService
            .getBalance(address: wallet.address)

        cancellable = balanceInfoPublisher
            .withWeakCaptureOf(self)
            .sink(receiveCompletion: { [weak self] result in
                switch result {
                case .failure(let error):
                    self?.wallet.clearAmounts()
                    completion(.failure(error))
                case .finished:
                    completion(.success(()))
                }
            }, receiveValue: { walletManager, balanceInfo in
                walletManager.updateWallet(balanceInfo: balanceInfo)
            })
    }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], any Error> {
        // TODO: - https://tangem.atlassian.net/browse/IOS-8316
        return .anyFail(error: WalletError.empty)
    }

    func send(_ transaction: Transaction, signer: any TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        let hashForSign: Data

        do {
            let transactionForSign = try transactionBuilder.buildForSign(transaction: transaction)
            hashForSign = transactionForSign.getSha256()
        } catch {
            return .sendTxFail(error: WalletError.failedToBuildTx)
        }

        return signer
            .sign(hash: hashForSign, walletPublicKey: wallet.publicKey)
            .withWeakCaptureOf(self)
            .flatMap { walletManager, signature -> AnyPublisher<String, Error> in
                guard let rawTransactionData = try? self.transactionBuilder.buildForSend(
                    transaction: transaction,
                    signature: signature.signature
                ) else {
                    return .anyFail(error: WalletError.failedToSendTx)
                }

                return .anyFail(error: WalletError.failedToSendTx)
            }
            .withWeakCaptureOf(self)
            .map { walletManager, transactionHash in
                let mapper = PendingTransactionRecordMapper()
                let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: transactionHash)
                walletManager.wallet.addPendingTransaction(record)
                return TransactionSendResult(hash: transactionHash)
            }
            .eraseSendError()
            .eraseToAnyPublisher()
    }

    // MARK: - Private Implementation

    private func updateWallet(balanceInfo: CasperBalance) {
        if balanceInfo.value != wallet.amounts[.coin]?.value {
            wallet.clearPendingTransaction()
        }

        wallet.add(amount: Amount(with: wallet.blockchain, type: .coin, value: balanceInfo.value))
    }
}

extension CasperWalletManager {
    enum Constants {
        static let constantFeeValue = Decimal(stringValue: "0.1")
    }
}
