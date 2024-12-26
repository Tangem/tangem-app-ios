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
    private let balanceProvider: TokenBalanceProvider
    private let fiatBalanceProvider: TokenBalanceProvider

    init(walletModel: WalletModel) {
        self.walletModel = walletModel

        balanceProvider = walletModel.combineBalanceProvider
        fiatBalanceProvider = walletModel.combineFiatBalanceProvider
    }
}

extension DefaultTokenItemInfoProvider: TokenItemInfoProvider {
    var id: WalletModel.ID { walletModel.id }

    var tokenItem: TokenItem { walletModel.tokenItem }

    var hasPendingTransactions: Bool { walletModel.hasPendingTransactions }

    var isZeroBalanceValue: Bool {
        walletModel.balanceState != .positive
    }

    var balance: TokenBalanceType {
        balanceProvider.balanceType
    }

    var quotePublisher: AnyPublisher<TokenQuote?, Never> {
        walletModel.ratePublisher.map { $0.quote }.eraseToAnyPublisher()
    }

    var balancePublisher: AnyPublisher<TokenBalanceType, Never> {
        balanceProvider.balanceTypePublisher
    }

    var balanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        balanceProvider.formattedBalanceTypePublisher
    }

    var fiatBalanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        fiatBalanceProvider.formattedBalanceTypePublisher
    }

    var actionsUpdatePublisher: AnyPublisher<Void, Never> { walletModel.actionsUpdatePublisher }

    var isStakedPublisher: AnyPublisher<Bool, Never> {
        walletModel.stakingManagerStatePublisher
            .filter { $0 != .loading }
            .map { state in
                switch state {
                case .staked: true
                case .loading, .availableToStake, .notEnabled, .temporaryUnavailable, .loadingError: false
                }
            }
            .eraseToAnyPublisher()
    }
}
