//
//  AlephiumWalletManager.swift
//  BlockchainSdk
//
//  Created by Alexander Skibin on 20.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class AlephiumWalletManager: BaseManager, WalletManager {
    var currentHost: String {
        networkService.host
    }

    var allowsFeeSelection: Bool {
        true
    }

    // MARK: - Private Implementation

    private let networkService: AlephiumNetworkService
    private let transactionBuilder: AlephiumTransactionBuilder

    // MARK: - Init

    init(wallet: Wallet, networkService: AlephiumNetworkService, transactionBuilder: AlephiumTransactionBuilder) {
        self.networkService = networkService
        self.transactionBuilder = transactionBuilder
        super.init(wallet: wallet)
    }

    // MARK: - Manager Implementation

    override func update(completion: @escaping (Result<Void, any Error>) -> Void) {
        let accountInfoPublisher = networkService
            .getAccountInfo(for: wallet.address)

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
            }, receiveValue: { walletManager, accountInfo in
                walletManager.updateWallet(accountInfo: accountInfo)
            })
    }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], any Error> {
        networkService.getFee(
            from: wallet.publicKey.blockchainKey.hexString,
            destination: destination,
            amount: amount.value.stringValue
        )
        .eraseToAnyPublisher()
    }

    func send(_ transaction: Transaction, signer: any TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        // TODO: - https://tangem.atlassian.net/browse/IOS-8988
        return .anyFail(error: SendTxError(error: WalletError.failedToSendTx))
    }

    // MARK: - Private Implementation
    
    private func updateWallet(accountInfo: AlephiumAccountInfo) {
        wallet.add(coinValue: accountInfo.balance.value)
        transactionBuilder.update(utxo: accountInfo.utxo)
    }
    
}

// MARK: - Constants

extension AlephiumWalletManager {
    enum Constants {
        static let dustAmountValue = Decimal(stringValue: "0.001")!
    }
}

// MARK: - DustRestrictable

extension AlephiumWalletManager: DustRestrictable {
    var dustValue: Amount {
        return Amount(with: wallet.blockchain, type: .coin, value: Constants.dustAmountValue)
    }
}
