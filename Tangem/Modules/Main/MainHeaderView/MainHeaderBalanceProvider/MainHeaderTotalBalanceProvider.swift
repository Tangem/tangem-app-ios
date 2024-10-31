//
//  MainHeaderTotalBalanceProvider.swift
//  Tangem
//
//  Created by Andrew Son on 09/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol MainHeaderBalanceProvider {
    var balanceProvider: AnyPublisher<LoadingValue<AttributedString>, Never> { get }
}

class CommonMainHeaderBalanceProvider {
    private let totalBalanceProvider: TotalBalanceProviding
    private let userWalletStateInfoProvider: MainHeaderUserWalletStateInfoProvider
    private let mainBalanceFormatter: MainHeaderBalanceFormatter

    private let headerBalanceSubject = CurrentValueSubject<LoadingValue<AttributedString>, Never>(.loading)
    private var balanceSubscription: AnyCancellable?

    init(
        totalBalanceProvider: TotalBalanceProviding,
        userWalletStateInfoProvider: MainHeaderUserWalletStateInfoProvider,
        mainBalanceFormatter: MainHeaderBalanceFormatter
    ) {
        self.totalBalanceProvider = totalBalanceProvider
        self.userWalletStateInfoProvider = userWalletStateInfoProvider
        self.mainBalanceFormatter = mainBalanceFormatter

        bind()
    }

    private func bind() {
        balanceSubscription = totalBalanceProvider.totalBalancePublisher
            .sink(receiveValue: { [weak self] newValue in
                guard let self else {
                    return
                }

                if userWalletStateInfoProvider.isUserWalletLocked {
                    return
                }

                switch newValue {
                case .loading:
                    headerBalanceSubject.send(.loading)
                case .loaded(let balance):
                    guard balance.allTokensBalancesIncluded else {
                        // We didn't show any error in header, so no need to specify error
                        headerBalanceSubject.send(.failedToLoad(error: ""))
                        return
                    }

                    var balanceToFormat = balance.balance
                    if balanceToFormat == nil, userWalletStateInfoProvider.isTokensListEmpty {
                        balanceToFormat = 0
                    }

                    let formattedForMainBalance = mainBalanceFormatter.formatBalance(balance: balanceToFormat, currencyCode: balance.currencyCode)
                    headerBalanceSubject.send(.loaded(formattedForMainBalance))
                case .failedToLoad(let error):
                    headerBalanceSubject.send(.failedToLoad(error: error))
                }
            })
    }
}

extension CommonMainHeaderBalanceProvider: MainHeaderBalanceProvider {
    var balanceProvider: AnyPublisher<LoadingValue<AttributedString>, Never> {
        headerBalanceSubject.eraseToAnyPublisher()
    }
}
