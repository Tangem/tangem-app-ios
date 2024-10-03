//
//  FakeCryptoBalanceProvider.swift
//  Tangem
//
//  Created by Andrew Son on 07/06/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class FakeTokenBalanceProvider {
    private let buttons: [FixedSizeButtonWithIconInfo]
    private let delay: TimeInterval
    private let cryptoBalanceInfo: WalletModel.BalanceFormatted

    private let valueSubject = CurrentValueSubject<LoadingValue<BalanceWithButtonsViewModel.Balances>, Never>(.loading)
    private let buttonsSubject: CurrentValueSubject<[FixedSizeButtonWithIconInfo], Never>

    var balancesPublisher: AnyPublisher<LoadingValue<BalanceWithButtonsViewModel.Balances>, Never> {
        scheduleSendingValue()
        return valueSubject.eraseToAnyPublisher()
    }

    var buttonsPublisher: AnyPublisher<[FixedSizeButtonWithIconInfo], Never> { buttonsSubject.eraseToAnyPublisher() }

    init(buttons: [FixedSizeButtonWithIconInfo], delay: TimeInterval, cryptoBalanceInfo: WalletModel.BalanceFormatted) {
        self.buttons = buttons
        buttonsSubject = .init(buttons)
        self.delay = delay
        self.cryptoBalanceInfo = cryptoBalanceInfo
    }

    private func scheduleSendingValue() {
        guard delay > 0 else {
            sendInfo()
            return
        }

        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
            self.sendInfo()
        }
    }

    private func sendInfo() {
        if cryptoBalanceInfo.crypto.contains("-1") {
            valueSubject.send(.failedToLoad(error: "Failed to load balance. Network unreachable"))
            buttonsSubject.send(disabledButtons())
        } else {
            valueSubject.send(.loaded(.init(all: cryptoBalanceInfo, available: cryptoBalanceInfo)))
        }
    }

    private func disabledButtons() -> [FixedSizeButtonWithIconInfo] {
        buttons.map { button in
            .init(title: button.title, icon: button.icon, disabled: true, action: button.action)
        }
    }
}
