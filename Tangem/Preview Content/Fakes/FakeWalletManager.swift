//
//  FakeWalletManager.swift
//  Tangem
//
//  Created by Andrew Son on 28/07/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class FakeWalletManager: WalletManager {
    @Published var wallet: Wallet
    @Published var state: WalletManagerState = .initial

    var cardTokens: [BlockchainSdk.Token] = []
    var currentHost: String = "tangem.com"
    var outputsCount: Int?
    var allowsFeeSelection: Bool = true

    var walletPublisher: AnyPublisher<Wallet, Never> { $wallet.eraseToAnyPublisher() }
    var statePublisher: AnyPublisher<WalletManagerState, Never> { $state.eraseToAnyPublisher() }

    init(wallet: BlockchainSdk.Wallet) {
        self.wallet = wallet
    }

    func setNeedsUpdate() {}

    func update() {}

    func updatePublisher() -> AnyPublisher<WalletManagerState, Never> {
        .just(output: state)
    }

    func removeToken(_ token: BlockchainSdk.Token) {
        cardTokens.removeAll(where: { $0 == token })
    }

    func addToken(_ token: BlockchainSdk.Token) {
        cardTokens.append(token)
    }

    func addTokens(_ tokens: [BlockchainSdk.Token]) {
        cardTokens.append(contentsOf: tokens)
    }

    func send(_ transaction: BlockchainSdk.Transaction, signer: BlockchainSdk.TransactionSigner) -> AnyPublisher<BlockchainSdk.TransactionSendResult, Error> {
        .justWithError(output: .init(hash: Data.randomData(count: 32).hexString))
    }

    func validate(fee: BlockchainSdk.Fee) throws {}

    func validate(amount: BlockchainSdk.Amount) throws {}

    func getFee(amount: BlockchainSdk.Amount, destination: String) -> AnyPublisher<[BlockchainSdk.Fee], Error> {
        .justWithError(output: [
            .init(amount),
            .init(amount),
            .init(amount),
        ])
    }
}
