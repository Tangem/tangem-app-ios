//
//  FiatBalanceProvider.swift
//  TangemApp
//
//  Created by Sergey Balashov on 24.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemStaking

struct FiatBalanceProvider {
    private let walletModel: WalletModel
    private let cryptoBalanceProvider: TokenBalanceProvider
    private let balanceFormatter = BalanceFormatter()

    init(walletModel: WalletModel, cryptoBalanceProvider: TokenBalanceProvider) {
        self.walletModel = walletModel
        self.cryptoBalanceProvider = cryptoBalanceProvider
    }
}

// MARK: - TokenBalanceProvider

extension FiatBalanceProvider: TokenBalanceProvider {
    var balanceType: TokenBalanceType {
        mapToTokenBalance(rate: walletModel.rate, balanceType: cryptoBalanceProvider.balanceType)
    }

    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> {
        Publishers.CombineLatest(
            // Listen if rate was loaded after main balance
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

extension FiatBalanceProvider {
    func mapToTokenBalance(rate: LoadingResult<WalletModel.Rate?, Never>, balanceType: TokenBalanceType) -> TokenBalanceType {
        switch (rate, balanceType) {
        // There is no rate because it's custom token
        case (.success(.none), _) where walletModel.isCustom:
            return .empty(.custom)

        // There is no crypto value to convert
        case (_, .empty(let reason)):
            return .empty(reason)

        // There is no rate but main balance is still loading
        // Then show loading to avoid showing empty fiat when crypto is loading
        case (.success(.none), .loading):
            return .loading(.none)

        // There is no rate
        case (.success(.none), _):
            return .empty(.noData)

        // There is no crypto value because there was an error
        case (_, .failure(.none)):
            return .failure(.none)

        // There is rate is loading and we can't convert it
        case (.loading, _), (_, .loading(.none)):
            return .loading(.none)

        // Has some rate and cached value
        case (.success(.some(let rate)), .loading(.some(let cached))):
            let fiat = cached.balance * rate.value
            return .loading(.init(balance: fiat, date: cached.date))

        // Has some rate and cached value
        case (.success(.some(let rate)), .failure(.some(let cached))):
            let fiat = cached.balance * rate.value
            return .failure(.init(balance: fiat, date: cached.date))

        // Has cached rate and cached value
        case (.success(.some(.cached(let rate))), .loaded(let value)):
            let fiat = value * rate.balance
            return .failure(.init(balance: fiat, date: rate.date))

        // Has some rate and cached value
        case (.success(.some(.actual(let rate))), .loaded(let value)):
            let fiat = value * rate
            return .loaded(fiat)
        }
    }

    func mapToFormattedTokenBalanceType(type: TokenBalanceType) -> FormattedTokenBalanceType {
        let builder = FormattedTokenBalanceTypeBuilder(format: { value in
            balanceFormatter.formatFiatBalance(value)
        })

        return builder.mapToFormattedTokenBalanceType(type: type)
    }
}
