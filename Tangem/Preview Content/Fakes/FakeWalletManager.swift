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
    @Published var state: WalletManagerState = .loading
    @Published var walletModels: [WalletModel] = []

    var cardTokens: [BlockchainSdk.Token] = []
    var currentHost: String = "tangem.com"
    var outputsCount: Int?
    var allowsFeeSelection: Bool = true

    var walletPublisher: AnyPublisher<Wallet, Never> { $wallet.eraseToAnyPublisher() }
    var statePublisher: AnyPublisher<WalletManagerState, Never> { $state.eraseToAnyPublisher() }

    private var loadingStateObserver: AnyCancellable?

    init(wallet: BlockchainSdk.Wallet, derivationStyle: DerivationStyle? = .v2) {
        self.wallet = wallet
        cardTokens = wallet.amounts.compactMap { $0.key.token }
        walletModels = CommonWalletModelsFactory(derivationStyle: derivationStyle).makeWalletModels(from: self)
        bind()
    }

    func scheduleSwitchFromLoadingState() {
        print("Scheduling switch from loading state")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.state = .loaded(self.wallet)
        }
    }

    func setNeedsUpdate() {}

    func update() {}

    func updatePublisher() -> AnyPublisher<WalletManagerState, Never> {
        print("Receive update request")

        return Just(nextState())
            .delay(for: 5, scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func removeToken(_ token: BlockchainSdk.Token) {
        cardTokens.removeAll(where: { $0 == token })
    }

    func addToken(_ token: BlockchainSdk.Token) {
        cardTokens.append(token)
        wallet.add(tokenValue: 0, for: token)
    }

    func addTokens(_ tokens: [BlockchainSdk.Token]) {
        cardTokens.append(contentsOf: tokens)
        tokens.forEach { wallet.add(tokenValue: 0, for: $0) }
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

    private func bind() {
        loadingStateObserver = $state.sink { state in
            if case .loading = state {
                self.scheduleSwitchFromLoadingState()
            }
        }
    }

    private func nextState() -> WalletManagerState {
        switch state {
        case .initial: return .loading
        case .loading: return .loaded(wallet)
        case .loaded: return .failed("Some Wallet manager error")
        case .failed: return .loading
        }
    }
}

extension FakeWalletManager {
    static let ethWithTokensManager: FakeWalletManager = {
        var wallet = Wallet.ethereumWalletStub
        wallet.add(coinValue: 15.929021455553232400354389)
        wallet.add(tokenValue: 124245648213146521.298278546, for: .sushiMock)
        wallet.add(tokenValue: 864, for: .tetherMock)
        wallet.add(tokenValue: 0.9991239124323274832932535, for: .inverseBTCBlaBlaBlaMock)
        return FakeWalletManager(wallet: wallet)
    }()

    static let polygonWithTokensManager: FakeWalletManager = {
        var wallet = Wallet.polygonWalletStub
        wallet.add(coinValue: 15.929003000000354389)
        wallet.add(tokenValue: 97642.298278546, for: .shibaInuMock)
        wallet.add(tokenValue: 864193.24382948329432, for: .cosmosMock)
        wallet.add(tokenValue: 123.9991239124323274832932535, for: .inverseBTCBlaBlaBlaMock)
        return FakeWalletManager(wallet: wallet)
    }()

    static let btcManager: FakeWalletManager = {
        var wallet = Wallet.btcWalletStub
        wallet.add(coinValue: 1423)
        return FakeWalletManager(wallet: wallet)
    }()

    static let xrpManager: FakeWalletManager = {
        var wallet = Wallet.xrpWalletStub
        wallet.add(coinValue: 5828830)
        return FakeWalletManager(wallet: wallet)
    }()
}
