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
    private let walletModel: WalletModel
    private let balanceFormatter = BalanceFormatter()

    init(walletModel: WalletModel) {
        self.walletModel = walletModel
    }
}

// MARK: - TokenBalanceProvider

extension AvailableBalanceProvider: TokenBalanceProvider {
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

private extension AvailableBalanceProvider {
    func mapToTokenBalance(state: WalletModel.State) -> TokenBalanceType {
        // The `binance` always has zero balance
        if case .binance = walletModel.tokenItem.blockchain {
            return .loaded(0)
        }

        switch state {
        case .created:
            return .empty(.noData)
        case .noDerivation:
            return .empty(.noDerivation)
        case .loading:
            return .loading(nil)
        case .loaded(let balance):
            return .loaded(balance)
        case .noAccount:
            return .noAccount
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
