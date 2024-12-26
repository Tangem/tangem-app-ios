//
//  AvailableTokenBalanceProvider.swift
//  TangemApp
//
//  Created by Sergey Balashov on 24.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// Just simple available to use (e.g. send) balance
struct AvailableTokenBalanceProvider {
    private let walletModel: WalletModel
    private let balanceFormatter = BalanceFormatter()

    init(walletModel: WalletModel) {
        self.walletModel = walletModel
    }
}

// MARK: - TokenBalanceProvider

extension AvailableTokenBalanceProvider: TokenBalanceProvider {
    var balanceType: TokenBalanceType {
        mapToTokenBalance(state: walletModel.state)
    }

    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> {
        walletModel.statePublisher
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

private extension AvailableTokenBalanceProvider {
    func mapToTokenBalance(state: WalletModel.State) -> TokenBalanceType {
        // The `binance` always has zero balance
        if case .binance = walletModel.tokenItem.blockchain {
            return .loaded(0)
        }

        switch state {
        case .created:
            return .empty(.noData)
        case .loading:
            return .loading(nil)
        case .loaded(let balance):
            return .loaded(balance)
        case .noAccount(let message, _):
            return .empty(.noAccount(message: message))
        case .failed:
            return .failure(nil)
        }
    }

    func mapToFormattedTokenBalanceType(type: TokenBalanceType) -> FormattedTokenBalanceType {
        let builder = FormattedTokenBalanceTypeBuilder(format: { value in
            balanceFormatter.formatCryptoBalance(value, currencyCode: walletModel.tokenItem.currencySymbol)
        })

        return builder.mapToFormattedTokenBalanceType(type: type)
    }
}
