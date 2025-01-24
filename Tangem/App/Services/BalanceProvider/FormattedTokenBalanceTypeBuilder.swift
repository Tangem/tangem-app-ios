//
//  FormattedTokenBalanceTypeBuilder.swift
//  TangemApp
//
//  Created by Sergey Balashov on 25.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct FormattedTokenBalanceTypeBuilder {
    private let format: (Decimal?) -> String

    init(format: @escaping (Decimal?) -> String) {
        self.format = format
    }

    func mapToFormattedTokenBalanceType(type: TokenBalanceType) -> FormattedTokenBalanceType {
        switch type {
        case .empty:
            return .loaded(format(.none))
        case .loading(.some(let cached)):
            return .loading(.cache(.init(balance: format(cached.balance), date: cached.date)))
        case .loading(.none):
            return .loading(.empty(format(.none)))
        case .failure(.some(let cached)):
            return .failure(.cache(.init(balance: format(cached.balance), date: cached.date)))
        case .failure(.none):
            return .failure(.empty(format(.none)))
        case .loaded(let balance):
            return .loaded(format(balance))
        }
    }
}
