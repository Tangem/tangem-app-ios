//
//  BaseManager.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 05.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

@available(iOS 13.0, *)
class BaseManager: WalletProvider {
    var wallet: Wallet {
        get { _wallet.value }
        set { _wallet.value = newValue }
    }

    var cardTokens: [Token] = []
    var cancellable: Cancellable? = nil

    var walletPublisher: AnyPublisher<Wallet, Never> { _wallet.eraseToAnyPublisher() }
    var statePublisher: AnyPublisher<WalletManagerState, Never> { state.eraseToAnyPublisher() }
    
    private var latestUpdateTime: Date?

    // TODO: move constant into config
    private var canUpdate: Bool {
        if let latestUpdateTime,
           latestUpdateTime.distance(to: Date()) <= 10 {
            return false
        }

        return true
    }

    private var _wallet: CurrentValueSubject<Wallet, Never>
    private var state: CurrentValueSubject<WalletManagerState, Never> = .init(.initial)
    private var loadingPublisher: PassthroughSubject<WalletManagerState, Never> = .init()

    init(wallet: Wallet) {
        _wallet = .init(wallet)
    }

    func update() {
        if state.value.isLoading {
            return
        }

        guard canUpdate else {
            didFinishUpdating(error: nil)
            return
        }

        state.send(.loading)

        update { [weak self] result in
            guard let self else { return }

            switch result {
            case .success:
                didFinishUpdating(error: nil)
                latestUpdateTime = Date()
            case .failure(let error):
                didFinishUpdating(error: error)
            }
        }
    }

    func update(completion: @escaping (Result<Void, Error>) -> Void) {}

    func setNeedsUpdate() {
        latestUpdateTime = nil
    }

    func removeToken(_ token: Token) {
        cardTokens.removeAll(where: { $0 == token })
        wallet.clearAmount(for: token)
    }

    func addToken(_ token: Token) {
        if !cardTokens.contains(token) {
            cardTokens.append(token)
        }
    }

    func addTokens(_ tokens: [Token]) {
        tokens.forEach { addToken($0) }
    }

    func updatePublisher() -> AnyPublisher<WalletManagerState, Never> {
        if !state.value.isLoading {
            // we should postpone an update call to prevent missing a cached value by PassthroughSubject
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.update()
            }
        }

        return loadingPublisher.eraseToAnyPublisher()
    }

    private func didFinishUpdating(error: Error?) {
        var newState: WalletManagerState

        if let error {
            newState = .failed(error)
        } else {
            newState = .loaded
        }

        state.send(newState)
        loadingPublisher.send(newState)
    }
}
