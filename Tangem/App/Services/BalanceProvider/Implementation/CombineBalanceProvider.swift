//
//  CombineBalanceProvider.swift
//  TangemApp
//
//  Created by Sergey Balashov on 24.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemStaking

/// Total crypto balance (available+staking)
struct CombineBalanceProvider {
    private let walletModel: WalletModel
    private let availableBalanceProvider: TokenBalanceProvider
    private let stakingBalanceProvider: TokenBalanceProvider

    private let balanceFormatter = BalanceFormatter()

    init(walletModel: WalletModel, availableBalanceProvider: TokenBalanceProvider, stakingBalanceProvider: TokenBalanceProvider) {
        self.walletModel = walletModel
        self.availableBalanceProvider = availableBalanceProvider
        self.stakingBalanceProvider = stakingBalanceProvider
    }
}

// MARK: - TokenBalanceProvider

extension CombineBalanceProvider: TokenBalanceProvider {
    var balanceType: TokenBalanceType {
        mapToAvailableTokenBalance(
            available: availableBalanceProvider.balanceType,
            staking: stakingBalanceProvider.balanceType
        )
    }

    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> {
        Publishers.CombineLatest(
            availableBalanceProvider.balanceTypePublisher.removeDuplicates(),
            stakingBalanceProvider.balanceTypePublisher.removeDuplicates()
        )
        .map { self.mapToAvailableTokenBalance(available: $0, staking: $1) }
        .eraseToAnyPublisher()
    }

    var formattedBalanceType: FormattedTokenBalanceType {
        mapToFormattedTokenBalanceType(type: balanceType)
    }

    var formattedBalanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        balanceTypePublisher
            .map { self.mapToFormattedTokenBalanceType(type: $0) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension CombineBalanceProvider {
    func mapToAvailableTokenBalance(available: TokenBalanceType, staking: TokenBalanceType) -> TokenBalanceType {
        switch (available, staking) {
        // There is no available balance -> no balance
        case (.empty(let reason), _):
            return .empty(reason)

        // There is only available -> show only available
        case (.loaded(let balance), .empty):
            return .loaded(balance)

        // Available is loading and staking is empty -> loading with cache
        case (.loading(.some(let available)), .empty):
            return .loading(.init(balance: available.balance, date: available.date))

        // Both is loading and both have a cache -> loading with cache
        case (.loading(.some(let available)), .loading(.some(let staking))):
            let cached = available.balance + staking.balance
            return .loading(.init(balance: cached, date: available.date))

        // Available is loading and staking is failure -> loading with cache + loaded
        case (.loading(.some(let available)), .failure(.some(let staking))):
            let cached = available.balance + staking.balance
            return .loading(.init(balance: cached, date: available.date))

        // Available is loading and staking is loaded -> loading with cache + loaded
        case (.loading(.some(let available)), .loaded(let staking)):
            let cached = available.balance + staking
            return .loading(.init(balance: cached, date: available.date))

        // Available is loaded and staking is loading -> loading with loaded + cache
        case (.loaded(let available), .loading(.some(let staking))):
            let cached = available + staking.balance
            return .loading(.init(balance: cached, date: staking.date))

        // Available is loaded and staking is loading -> loading with loaded + cache
        case (.failure(.some(let available)), .loading(.some(let staking))):
            let cached = available.balance + staking.balance
            return .loading(.init(balance: cached, date: available.date))

        // There is one of them is loading without cached -> loading without cache
        case (.loading(.none), _), (_, .loading(.none)):
            return .loading(.none)

        // Both is failure and both have a cache -> failure with cache
        case (.failure(.some(let available)), .failure(.some(let staking))):
            let cached = available.balance + staking.balance
            return .failure(.init(balance: cached, date: available.date))

        // Available is failure and staking is empty -> loading with cache
        case (.failure(.some(let available)), .empty):
            return .failure(.init(balance: available.balance, date: available.date))

        case (.failure(.some(let available)), .loaded(let staking)):
            let cached = available.balance + staking
            return .failure(.init(balance: cached, date: available.date))

        case (.loaded(let available), .failure(.some(let staking))):
            let cached = available + staking.balance
            return .failure(.init(balance: cached, date: staking.date))

        // There is one of them is failure without cached -> show error
        case (.failure(.none), _), (_, .failure(.none)):
            return .failure(.none)

        // There is both is loaded -> show loaded with sum
        case (.loaded(let available), .loaded(let staking)):
            return .loaded(available + staking)
        }
    }

    func mapToFormattedTokenBalanceType(type: TokenBalanceType) -> FormattedTokenBalanceType {
        let builder = FormattedTokenBalanceTypeBuilder(format: { value in
            balanceFormatter.formatCryptoBalance(value, currencyCode: walletModel.tokenItem.currencySymbol)
        })

        return builder.mapToFormattedTokenBalanceType(type: type)
    }
}
