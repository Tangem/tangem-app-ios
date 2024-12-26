//
//  StakingBalanceProvider.swift
//  TangemApp
//
//  Created by Sergey Balashov on 25.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking

struct StakingBalanceProvider {
    private let walletModel: WalletModel
    private let tokenBalancesRepository: TokenBalancesRepository
    private let balanceFormatter = BalanceFormatter()

    init(walletModel: WalletModel, tokenBalancesRepository: TokenBalancesRepository) {
        self.walletModel = walletModel
        self.tokenBalancesRepository = tokenBalancesRepository
    }
}

// MARK: - TokenBalanceProvider

extension StakingBalanceProvider: TokenBalanceProvider {
    var balanceType: TokenBalanceType {
        mapToTokenBalance(state: walletModel.stakingManagerState)
    }

    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> {
        walletModel.stakingManagerStatePublisher
            .map { self.mapToTokenBalance(state: $0) }
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

extension StakingBalanceProvider {
    func storeBalance(balance: Decimal) {
        tokenBalancesRepository.storeStaking(
            balance: .init(balance: balance, date: .now),
            for: walletModel.tokenItem
        )
    }

    func cachedBalance() -> TokenBalanceType.Cached? {
        tokenBalancesRepository.stakingBalance(tokenItem: walletModel.tokenItem).map {
            .init(balance: $0.balance, date: $0.date)
        }
    }

    func mapToTokenBalance(state: StakingManagerState) -> TokenBalanceType {
        switch state {
        case .loading:
            return .loading(cachedBalance())
        case .notEnabled, .temporaryUnavailable:
            return .empty(.noData)
        case .loadingError:
            return .failure(cachedBalance())
        case .availableToStake:
            return .loaded(.zero)
        case .staked(let balances):
            let balance = balances.balances.blocked().sum()
            storeBalance(balance: balance)
            return .loaded(balance)
        }
    }

    func mapToFormattedTokenBalanceType(type: TokenBalanceType) -> FormattedTokenBalanceType {
        let builder = FormattedTokenBalanceTypeBuilder(format: { value in
            balanceFormatter.formatCryptoBalance(value, currencyCode: walletModel.tokenItem.currencySymbol)
        })

        return builder.mapToFormattedTokenBalanceType(type: type)
    }
}
