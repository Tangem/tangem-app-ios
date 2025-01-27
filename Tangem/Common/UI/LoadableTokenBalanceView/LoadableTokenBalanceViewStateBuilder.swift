//
//  LoadableTokenBalanceViewStateBuilder.swift
//  TangemApp
//
//  Created by Sergey Balashov on 10.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct LoadableTokenBalanceViewStateBuilder {
    func build(type: FormattedTokenBalanceType, icon: LoadableTokenBalanceView.State.Icon? = nil) -> LoadableTokenBalanceView.State {
        switch type {
        case .loading(.cache(let cached)):
            .loading(cached: .string(cached.balance)) // Shining text
        case .loading(.empty):
            .loading(cached: .none) // Usual skeleton
        case .failure(.empty(let string)):
            .failed(cached: .string(string))
        case .failure(.cache(let cache)):
            .failed(cached: .string(cache.balance), icon: icon)
        case .loaded(let string):
            .loaded(text: .string(string))
        }
    }

    func buildAttributedTotalBalance(type: FormattedTokenBalanceType) -> LoadableTokenBalanceView.State {
        let formatter = BalanceFormatter()

        switch type {
        case .loading(.cache(let cached)):
            let attributed = formatter.formatAttributedTotalBalance(fiatBalance: cached.balance)
            return .loading(cached: .attributed(attributed)) // Shining text
        case .loading(.empty):
            return .loading(cached: .none) // Usual skeleton
        case .failure(let cachedType):
            let attributed = formatter.formatAttributedTotalBalance(fiatBalance: cachedType.value)
            return .failed(cached: .attributed(attributed), icon: .none)
        case .loaded(let string):
            let attributed = formatter.formatAttributedTotalBalance(fiatBalance: string)
            return .loaded(text: .attributed(attributed))
        }
    }

    func buildTotalBalance(state: TotalBalanceState) -> LoadableTokenBalanceView.State {
        let formatter = BalanceFormatter()

        switch state {
        case .empty:
            return .empty
        case .loading(.none):
            return .loading(cached: .none)
        case .loading(.some(let cached)):
            let formatted = formatter.formatFiatBalance(cached)
            return .loading(cached: .string(formatted))
        case .failed(.none, _):
            return .failed(cached: .string(Localization.commonUnreachable))
        case .failed(.some(let cached), _):
            let formatted = formatter.formatFiatBalance(cached)
            return .failed(cached: .string(formatted), icon: .trailing)
        case .loaded(let balance):
            let formatted = formatter.formatFiatBalance(balance)
            return .loaded(text: .string(formatted))
        }
    }
}
