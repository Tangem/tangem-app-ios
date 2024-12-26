//
//  TokenWithoutDerivationInfoProvider.swift
//  Tangem
//
//  Created by Andrew Son on 08/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class TokenWithoutDerivationInfoProvider: TokenItemInfoProvider {
    let id: Int
    let tokenItem: TokenItem
    let hasPendingTransactions: Bool = false
    var isZeroBalanceValue: Bool { true }
    var balance: TokenBalanceType { .empty(.noDerivation) }

    var quotePublisher: AnyPublisher<TokenQuote?, Never> { .just(output: .none) }
    var balancePublisher: AnyPublisher<TokenBalanceType, Never> { .just(output: balance) }
    var balanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { .just(output: .loaded("-")) }
    var fiatBalanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { .just(output: .loaded("-")) }
    var actionsUpdatePublisher: AnyPublisher<Void, Never> { .just(output: ()) }
    var isStakedPublisher: AnyPublisher<Bool, Never> { .just(output: false) }

    init(id: Int, tokenItem: TokenItem) {
        self.id = id
        self.tokenItem = tokenItem
    }
}
