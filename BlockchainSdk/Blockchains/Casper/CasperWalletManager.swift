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
        // TODO: - https://tangem.atlassian.net/browse/IOS-8316
        ""
    }

    var allowsFeeSelection: Bool {
        false
    }

    override func update(completion: @escaping (Result<Void, any Error>) -> Void) {
        // TODO: - https://tangem.atlassian.net/browse/IOS-8316
    }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], any Error> {
        // TODO: - https://tangem.atlassian.net/browse/IOS-8316
        return .anyFail(error: WalletError.empty)
    }

    func send(_ transaction: Transaction, signer: any TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        // TODO: - https://tangem.atlassian.net/browse/IOS-8316
        return .anyFail(error: SendTxError(error: WalletError.empty))
    }
    
    // MARK: - Private Implementation
    
    private func updateWallet(balance: CasperBalance) {
        if balance.value != wallet.amounts[.coin]?.value {
            wallet.clearPendingTransaction()
        }
        
        wallet.add(amount: Amount(with: wallet.blockchain, type: .coin, value: balance.value))
    }
    
}

extension CasperWalletManager {
    enum Constants {
        static let constantFeeValue = Decimal(stringValue: "0.1")
    }
}
