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
    let balance: String = Localization.walletBalanceMissingDerivation
    let fiatBalance: String = BalanceFormatter.defaultEmptyBalanceString

    var tokenItemStatePublisher: AnyPublisher<TokenItemViewState, Never> { .just(output: .noDerivation) }

    init(id: Int, tokenItem: TokenItem) {
        self.id = id
        self.tokenItem = tokenItem
    }
}
