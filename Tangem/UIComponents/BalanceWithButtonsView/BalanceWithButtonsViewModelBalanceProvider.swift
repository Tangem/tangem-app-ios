//
//  BalanceWithButtonsViewModelBalanceProvider.swift
//  TangemApp
//
//  Created by Sergey Balashov on 26.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine

protocol BalanceWithButtonsViewModelBalanceProvider {
    var totalCryptoBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { get }
    var totalFiatBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { get }

    var availableCryptoBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { get }
    var availableFiatBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { get }
}
