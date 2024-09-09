//
//  DefaultTokenItemInfoProvider.swift
//  Tangem
//
//  Created by Andrew Son on 11/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class DefaultTokenItemInfoProvider {
    private let walletModel: WalletModel

    init(walletModel: WalletModel) {
        self.walletModel = walletModel
    }
}

extension DefaultTokenItemInfoProvider: TokenItemInfoProvider {
    var id: Int { walletModel.id }

    var tokenItemState: TokenItemViewState {
        TokenItemViewState(walletModelState: walletModel.state)
    }

    var tokenItemStatePublisher: AnyPublisher<TokenItemViewState, Never> {
        Publishers.CombineLatest(
            walletModel.walletDidChangePublisher,
            walletModel.stakingManagerStatePublisher
        )
        .map { state, _ in
            TokenItemViewState(walletModelState: state)
        }
        .eraseToAnyPublisher()
    }

    var tokenItem: TokenItem { walletModel.tokenItem }

    var hasPendingTransactions: Bool { walletModel.hasPendingTransactions }

    var balance: String { walletModel.allBalanceFormatted.crypto }

    var fiatBalance: String { walletModel.allBalanceFormatted.fiat }

    var quote: TokenQuote? { walletModel.quote }

    var actionsUpdatePublisher: AnyPublisher<Void, Never> { walletModel.actionsUpdatePublisher }

    var isStaked: AnyPublisher<Bool, Never> {
        walletModel.stakingManagerStatePublisher
            .map { state in
                switch state {
                case .staked: true
                case .loading, .availableToStake, .notEnabled, .temporaryUnavailable: false
                }
            }
            .eraseToAnyPublisher()
    }
}
