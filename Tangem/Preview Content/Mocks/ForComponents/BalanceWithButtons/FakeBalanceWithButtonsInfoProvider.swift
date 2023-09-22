//
//  FakeBalanceWithButtonsInfoProvider.swift
//  Tangem
//
//  Created by Andrew Son on 07/06/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class FakeBalanceWithButtonsInfoProvider {
    @Published var models: [BalanceWithButtonsViewModel] = []

    private let balanceProviders = [
        FakeTokenBalanceProvider(
            buttons: [
                .init(title: "Buy", icon: Assets.plusMini, action: {}, disabled: true),
                .init(title: "Send", icon: Assets.arrowUpMini, action: {}, disabled: false),
            ],
            delay: 5,
            cryptoBalanceInfo: .init(balance: "1034.435432 ETH", fiatBalance: "–")
        ),
        FakeTokenBalanceProvider(
            buttons: [],
            delay: 0,
            cryptoBalanceInfo: .init(balance: "1031232431232151004.435432 BTC", fiatBalance: "–")
        ),
        FakeTokenBalanceProvider(
            buttons: [
                .init(title: "Buy", icon: Assets.plusMini, action: {}, disabled: false),
                .init(title: "Send", icon: Assets.arrowUpMini, action: {}, disabled: false),
                .init(title: "Receive", icon: Assets.arrowDownMini, action: {}),
                .init(title: "Exchange", icon: Assets.exchangeMini, action: {}, disabled: false),
                .init(title: "Sell your soul", icon: Assets.cryptoCurrencies, action: {}, disabled: false),
                .init(title: "Dance", icon: Assets.swapHeart, action: {}, disabled: false),
            ],
            delay: 3,
            cryptoBalanceInfo: .init(balance: "-1 MATIC", fiatBalance: "–")
        ),
        FakeTokenBalanceProvider(
            buttons: [
                .init(title: "Buy", icon: Assets.plusMini, action: {}),
                .init(title: "Send", icon: Assets.arrowUpMini, action: {}),
            ],
            delay: 6,
            cryptoBalanceInfo: .init(balance: "4.4212312 XLM", fiatBalance: "2.24$")
        ),
    ]

    init() {
        models = balanceProviders.map {
            BalanceWithButtonsViewModel(
                balanceProvider: $0,
                buttonsProvider: $0
            )
        }
    }
}
