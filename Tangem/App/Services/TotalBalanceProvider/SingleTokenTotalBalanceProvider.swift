//
//  SingleTokenTotalBalanceProvider.swift
//  Tangem
//
//  Created by Andrew Son on 14/12/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class SingleTokenTotalBalanceProvider {
    private let totalBalanceSubject: CurrentValueSubject<LoadingValue<TotalBalance>, Never>

    private let walletModel: WalletModel
    private let isFiat: Bool

    private var walletStateUpdateSubscription: AnyCancellable?

    init(walletModel: WalletModel, isFiat: Bool) {
        self.walletModel = walletModel
        self.isFiat = isFiat
        totalBalanceSubject = .init(.loading)

        bind()
    }

    private func bind() {
        walletStateUpdateSubscription = walletModel.walletDidChangePublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { balanceProvider, newState in
                let walletModel = balanceProvider.walletModel
                let currencySymbol = balanceProvider.isFiat ? AppSettings.shared.selectedCurrencyCode : walletModel.tokenItem.currencySymbol
                switch newState {
                case .loading, .created:
                    break
                case .failed, .noDerivation:
                    balanceProvider.totalBalanceSubject.send(
                        .loaded(.init(
                            balance: nil,
                            currencyCode: currencySymbol,
                            hasError: false,
                            allTokensBalancesIncluded: true
                        ))
                    )
                case .loaded, .noAccount:
                    balanceProvider.totalBalanceSubject.send(
                        .loaded(.init(
                            balance: balanceProvider.isFiat ? walletModel.fiatValue : walletModel.balanceValue,
                            currencyCode: currencySymbol,
                            hasError: false,
                            allTokensBalancesIncluded: true
                        ))
                    )
                }
            })
    }
}

extension SingleTokenTotalBalanceProvider: TotalBalanceProviding {
    var totalBalancePublisher: AnyPublisher<LoadingValue<TotalBalance>, Never> {
        totalBalanceSubject.eraseToAnyPublisher()
    }
}
