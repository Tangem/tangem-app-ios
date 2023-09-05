//
//  SendCurrencyViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 17.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct SendCurrencyViewModel: Identifiable {
    var id: Int { hashValue }

    // ViewState
    private(set) var maximumFractionDigits: Int
    private(set) var canChangeCurrency: Bool
    private(set) var balance: State
    private(set) var fiatValue: State

    let tokenIcon: SwappingTokenIconViewModel

    var balanceString: String {
        let balance = balance.value ?? 0
        return balance.groupedFormatted()
    }

    var fiatValueString: String {
        let fiatValue = fiatValue.value ?? 0
        return fiatValue.currencyFormatted(code: AppSettings.shared.selectedCurrencyCode)
    }

    init(
        balance: State,
        fiatValue: State,
        maximumFractionDigits: Int,
        canChangeCurrency: Bool,
        tokenIcon: SwappingTokenIconViewModel
    ) {
        self.balance = balance
        self.fiatValue = fiatValue
        self.maximumFractionDigits = maximumFractionDigits
        self.canChangeCurrency = canChangeCurrency
        self.tokenIcon = tokenIcon
    }

    func textFieldDidTapped() {
        Analytics.log(.swapSendTokenBalanceClicked)
    }

    mutating func update(balance: State) {
        self.balance = balance
    }

    mutating func update(fiatValue: State) {
        self.fiatValue = fiatValue
    }

    mutating func update(maximumFractionDigits: Int) {
        self.maximumFractionDigits = maximumFractionDigits
    }
}

extension SendCurrencyViewModel {
    enum State: Hashable {
        case loading
        case loaded(_ value: Decimal)

        var value: Decimal? {
            switch self {
            case .loaded(let value):
                return value
            default:
                return nil
            }
        }
    }
}

extension SendCurrencyViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(balance)
        hasher.combine(fiatValue)
        hasher.combine(maximumFractionDigits)
        hasher.combine(canChangeCurrency)
        hasher.combine(tokenIcon)
    }
}
