//
//  TokenItemInfoProvider.swift
//  Tangem
//
//  Created by Andrew Son on 28/04/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk

protocol TokenItemInfoProvider: AnyObject {
    var id: WalletModel.ID { get }
    var tokenItem: TokenItem { get }
    var hasPendingTransactions: Bool { get }
    var isZeroBalanceValue: Bool { get }
    var balance: TokenBalanceType { get }

    var quotePublisher: AnyPublisher<TokenQuote?, Never> { get }
    var balancePublisher: AnyPublisher<TokenBalanceType, Never> { get }
    var balanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { get }
    var fiatBalanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { get }

    var actionsUpdatePublisher: AnyPublisher<Void, Never> { get }
    var isStakedPublisher: AnyPublisher<Bool, Never> { get }
}
