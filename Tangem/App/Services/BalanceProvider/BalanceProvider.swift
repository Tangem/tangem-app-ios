//
//  TokenBalanceProvider.swift
//  TangemApp
//
//  Created by Sergey Balashov on 24.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

protocol TokenBalanceProvider {
    var balanceType: TokenBalanceType { get }
    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> { get }

    var formattedBalanceType: FormattedTokenBalanceType { get }
    var formattedBalanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { get }
}
