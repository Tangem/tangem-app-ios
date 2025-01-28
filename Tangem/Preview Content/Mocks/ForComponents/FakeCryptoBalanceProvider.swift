//
//  FakeCryptoBalanceProvider.swift
//  Tangem
//
//  Created by Andrew Son on 07/06/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

class FakeTokenBalanceProvider {
    typealias BalanceFormatted = (crypto: String, fiat: String)

    private let buttons: [FixedSizeButtonWithIconInfo]
    private let delay: TimeInterval
    private let cryptoBalanceInfo: BalanceFormatted

    private let valueSubject = CurrentValueSubject<LoadingResult<BalanceFormatted?, Never>, Never>(.loading)
    private let buttonsSubject: CurrentValueSubject<[FixedSizeButtonWithIconInfo], Never>

    var buttonsPublisher: AnyPublisher<[FixedSizeButtonWithIconInfo], Never> { buttonsSubject.eraseToAnyPublisher() }

    init(buttons: [FixedSizeButtonWithIconInfo], delay: TimeInterval, cryptoBalanceInfo: BalanceFormatted) {
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
            valueSubject.send(.success(nil))
            buttonsSubject.send(disabledButtons())
        } else {
            valueSubject.send(.success(cryptoBalanceInfo))
        }
    }

    private func disabledButtons() -> [FixedSizeButtonWithIconInfo] {
        buttons.map { button in
            .init(title: button.title, icon: button.icon, disabled: true, action: button.action)
        }
    }
}

extension FakeTokenBalanceProvider: BalanceWithButtonsViewModelBalanceProvider {
    var totalCryptoBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        valueSubject
            .withWeakCaptureOf(self)
            .map { $0.mapToFormattedTokenBalanceType(balance: $1, isCrypto: true) }
            .eraseToAnyPublisher()
    }

    var totalFiatBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        valueSubject
            .withWeakCaptureOf(self)
            .map { $0.mapToFormattedTokenBalanceType(balance: $1, isCrypto: false) }
            .eraseToAnyPublisher()
    }

    var availableCryptoBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        valueSubject
            .withWeakCaptureOf(self)
            .map { $0.mapToFormattedTokenBalanceType(balance: $1, isCrypto: true) }
            .eraseToAnyPublisher()
    }

    var availableFiatBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        valueSubject
            .withWeakCaptureOf(self)
            .map { $0.mapToFormattedTokenBalanceType(balance: $1, isCrypto: false) }
            .eraseToAnyPublisher()
    }

    private func mapToFormattedTokenBalanceType(balance: LoadingResult<BalanceFormatted?, Never>, isCrypto: Bool) -> FormattedTokenBalanceType {
        switch balance {
        case .loading: .loading(.empty("-"))
        case .success(let value): .loaded(isCrypto ? (value?.crypto ?? "-") : (value?.fiat ?? "-"))
        case .failure: .failure(.empty("-"))
        }
    }
}
