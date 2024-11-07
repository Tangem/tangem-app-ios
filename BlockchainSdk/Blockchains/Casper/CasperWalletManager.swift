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

    // MARK: - Init

    init(wallet: Wallet, networkService: CasperNetworkService) {
        self.networkService = networkService
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
        // TODO: - https://tangem.atlassian.net/browse/IOS-8317
        return .anyFail(error: WalletError.empty)
    }

    func send(_ transaction: Transaction, signer: any TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        // TODO: - https://tangem.atlassian.net/browse/IOS-8317
        return .anyFail(error: SendTxError(error: WalletError.empty))
    }

    // MARK: - Private Implementation

    private func updateWallet(balanceInfo: CasperBalance) {
        if balanceInfo.value != wallet.amounts[.coin]?.value {
            wallet.clearPendingTransaction()
        }

        wallet.add(amount: Amount(with: wallet.blockchain, type: .coin, value: balanceInfo.value))
    }
}

private extension CasperWalletManager {
    enum Constants {
        static let constantFeeValue = Decimal(stringValue: "0.1")
    }
}
