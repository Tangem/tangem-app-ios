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
            availableBalanceProvider.balanceTypePublisher,
            stakingBalanceProvider.balanceTypePublisher
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
        case (.empty, _):
            return .empty(.noData)

        // There is one of them is loading -> loading
        case (.loading, _), (_, .loading):
            return .loading(nil)

        // There is only available -> show only available
        case (.loaded(let balance), .empty):
            return .loaded(balance)

        // There is one of them is failure -> show error
        case (.failure, _), (_, .failure):
            return .failure(nil)

        // There is both is loaded -> show sum
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
