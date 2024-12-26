//
//  AvailableBalanceProvider.swift
//  TangemApp
//
//  Created by Sergey Balashov on 24.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// Just simple available to use (e.g. send) balance
struct AvailableBalanceProvider {
    @Injected(\.tokenBalancesRepository)
    private var tokenBalancesRepository: TokenBalancesRepository

    private let walletModel: WalletModel
    private let balanceFormatter = BalanceFormatter()

    init(walletModel: WalletModel) {
        self.walletModel = walletModel
    }
}

// MARK: - TokenBalanceProvider

extension AvailableBalanceProvider: TokenBalanceProvider {
    var balanceType: TokenBalanceType {
        mapToAvailableTokenBalance(state: walletModel.state)
    }

    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> {
        walletModel.statePublisher
            .map { self.mapToAvailableTokenBalance(state: $0) }
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

private extension AvailableBalanceProvider {
    func storeBalance(balance: Decimal) {
        tokenBalancesRepository.store(
            balance: .init(balance: balance, date: .now),
            for: walletModel,
            type: .available
        )
    }

    func cachedBalance() -> TokenBalanceType.Cached? {
        tokenBalancesRepository.balance(wallet: walletModel, type: .available).map {
            .init(balance: $0.balance, date: $0.date)
        }
    }

    func mapToAvailableTokenBalance(state: WalletModel.State) -> TokenBalanceType {
        // The `binance` always has zero balance
        if case .binance = walletModel.tokenItem.blockchain {
            return .loaded(0)
        }

        switch state {
        case .created:
            return .empty(.noData)
        case .loading:
            return .loading(cachedBalance())
        case .loaded(let balance):
            storeBalance(balance: balance)
            return .loaded(balance)
        case .noAccount(let message, _):
            return .empty(.noAccount(message: message))
        case .failed:
            return .failure(cachedBalance())
        }
    }

    func mapToFormattedTokenBalanceType(type: TokenBalanceType) -> FormattedTokenBalanceType {
        let builder = FormattedTokenBalanceTypeBuilder(format: { value in
            balanceFormatter.formatCryptoBalance(value, currencyCode: walletModel.tokenItem.currencySymbol)
        })

        return builder.mapToFormattedTokenBalanceType(type: type)
    }
}
