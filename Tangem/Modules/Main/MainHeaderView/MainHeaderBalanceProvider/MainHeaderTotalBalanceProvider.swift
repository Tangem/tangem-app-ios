//
//  MainHeaderTotalBalanceProvider.swift
//  Tangem
//
//  Created by Andrew Son on 09/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

protocol MainHeaderBalanceProvider {
    var balanceProvider: AnyPublisher<LoadableTokenBalanceView.State, Never> { get }
}

class CommonMainHeaderBalanceProvider {
    private let totalBalanceProvider: TotalBalanceProviding
    private let userWalletStateInfoProvider: MainHeaderUserWalletStateInfoProvider
    private let mainBalanceFormatter: MainHeaderBalanceFormatter

    private let headerBalanceSubject = CurrentValueSubject<LoadableTokenBalanceView.State, Never>(.loading())
    private var balanceSubscription: AnyCancellable?

    init(
        totalBalanceProvider: TotalBalanceProviding,
        userWalletStateInfoProvider: MainHeaderUserWalletStateInfoProvider,
        mainBalanceFormatter: MainHeaderBalanceFormatter
    ) {
        self.totalBalanceProvider = totalBalanceProvider
        self.userWalletStateInfoProvider = userWalletStateInfoProvider
        self.mainBalanceFormatter = mainBalanceFormatter

        bind()
    }

    private func bind() {
        balanceSubscription = totalBalanceProvider
            .totalBalancePublisher
            .withWeakCaptureOf(self)
            .sink(receiveValue: { provider, state in
                if provider.userWalletStateInfoProvider.isUserWalletLocked {
                    return
                }

                let state = provider.mapToLoadableTokenBalanceViewState(state: state)
                provider.headerBalanceSubject.send(state)
            })
    }

    private func mapToLoadableTokenBalanceViewState(state: TotalBalanceState) -> LoadableTokenBalanceView.State {
        switch state {
        case .empty, .failed(.none, _):
            let formatted = mainBalanceFormatter.formatBalance(balance: .none)
            return .failed(cached: .attributed(formatted))
        case .loading(let cached):
            let formatted = cached.map { self.mainBalanceFormatter.formatBalance(balance: $0) }
            return .loading(cached: formatted.map { .attributed($0) })
        case .failed(.some(let cached), _):
            let formatted = mainBalanceFormatter.formatBalance(balance: cached)
            return .failed(cached: .attributed(formatted))
        case .loaded(let balance):
            let formatted = mainBalanceFormatter.formatBalance(balance: balance)
            return .loaded(text: .attributed(formatted))
        }
    }
}

// MARK: - MainHeaderBalanceProvider

extension CommonMainHeaderBalanceProvider: MainHeaderBalanceProvider {
    var balanceProvider: AnyPublisher<LoadableTokenBalanceView.State, Never> {
        headerBalanceSubject.eraseToAnyPublisher()
    }
}
