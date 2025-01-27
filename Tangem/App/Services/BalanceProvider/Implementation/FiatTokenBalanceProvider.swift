//
//  FiatTokenBalanceProvider.swift
//  TangemApp
//
//  Created by Sergey Balashov on 24.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemStaking

struct FiatTokenBalanceProvider {
    private let walletModel: WalletModel
    private let cryptoBalanceProvider: TokenBalanceProvider
    private let balanceFormatter = BalanceFormatter()

    init(walletModel: WalletModel, cryptoBalanceProvider: TokenBalanceProvider) {
        self.walletModel = walletModel
        self.cryptoBalanceProvider = cryptoBalanceProvider
    }
}

// MARK: - TokenBalanceProvider

extension FiatTokenBalanceProvider: TokenBalanceProvider {
    var balanceType: TokenBalanceType {
        mapToTokenBalance(rate: walletModel.rate, balanceType: cryptoBalanceProvider.balanceType)
    }

    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> {
        Publishers.CombineLatest(
            walletModel.ratePublisher.removeDuplicates(),
            cryptoBalanceProvider.balanceTypePublisher.removeDuplicates()
        )
        .map { self.mapToTokenBalance(rate: $0, balanceType: $1) }
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

extension FiatTokenBalanceProvider {
    func mapToTokenBalance(rate: WalletModel.Rate, balanceType: TokenBalanceType) -> TokenBalanceType {
        switch (rate, balanceType) {
        // There is no rate because token is custom
        case (.custom, _):
            return .empty(.custom)

        // There is no crypto
        case (_, .empty(let reason)):
            return .empty(reason)

        // Main balance is still loading
        // Then show loading to avoid showing empty fiat when crypto is loading
        // Or rate is loading
        case (_, .loading(.none)), (.loading(.none), _):
            return .loading(.none)

        // There is no crypto or no rate value without cache
        case (.failure(.none), _), (_, .failure(.none)):
            return .failure(.none)

        // Both is loading and has cached value
        case (.loading(.some(let rate)), .loading(.some(let cached))):
            let fiat = cached.balance * rate.price
            return .loading(.init(balance: fiat, date: cached.date))

        // Both is failure and has cached value
        case (.failure(.some(let rate)), .failure(.some(let cached))):
            let fiat = cached.balance * rate.price
            return .failure(.init(balance: fiat, date: cached.date))

        // Has some rate and loading cached value
        case (.loaded(let rate), .loading(.some(let cached))):
            let fiat = cached.balance * rate.price
            return .loading(.init(balance: fiat, date: cached.date))

        // Has some rate and failure cached value
        case (.loaded(let rate), .failure(.some(let cached))):
            let fiat = cached.balance * rate.price
            return .failure(.init(balance: fiat, date: cached.date))

        // Has some rate and loaded value
        case (.loaded(let rate), .loaded(let value)):
            let fiat = value * rate.price
            return .loaded(fiat)

        // Has some cached rate and loading cached value
        case (.failure(.some(let rate)), .loading(.some(let cached))):
            let fiat = cached.balance * rate.price
            return .loading(.init(balance: fiat, date: rate.date))

        // Has some cached rate and loaded crypto value
        case (.failure(.some(let rate)), .loaded(let value)):
            let fiat = value * rate.price
            return .failure(.init(balance: fiat, date: rate.date))

        // Rate is loading with cached value and crypto cached value
        case (.loading(.some(let rate)), .failure(.some(let cached))):
            let fiat = cached.balance * rate.price
            return .loading(.init(balance: fiat, date: rate.date))

        // Rate is loading with cached value and crypto loaded value
        case (.loading(.some(let rate)), .loaded(let value)):
            let fiat = value * rate.price
            return .loading(.init(balance: fiat, date: rate.date))
        }
    }

    func mapToFormattedTokenBalanceType(type: TokenBalanceType) -> FormattedTokenBalanceType {
        let builder = FormattedTokenBalanceTypeBuilder(format: { value in
            balanceFormatter.formatFiatBalance(value)
        })

        return builder.mapToFormattedTokenBalanceType(type: type)
    }
}
