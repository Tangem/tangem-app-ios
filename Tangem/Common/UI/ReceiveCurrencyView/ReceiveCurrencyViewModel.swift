//
//  ReceiveCurrencyViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 17.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class ReceiveCurrencyViewModel: ObservableObject, Identifiable {
    @Published var canChangeCurrency: Bool
    @Published var balance: State
    @Published var cryptoAmountState: State
    @Published var fiatAmountState: State
    @Published var tokenIconState: SwappingTokenIconView.State
    @Published var isAvailable: Bool = true

    var balanceString: String {
        switch balance {
        case .idle:
            return ""
        case .loading:
            return "0"
        case .loaded(let value):
            return value.groupedFormatted()
        case .formatted(let value):
            return value
        }
    }

    var cryptoAmountFormatted: String {
        switch cryptoAmountState {
        case .idle:
            return ""
        case .loading:
            return "0"
        case .loaded(let value):
            let formatter = DecimalNumberFormatter(maximumFractionDigits: 8)
            return formatter.format(value: value)
        case .formatted(let value):
            return value
        }
    }

    var fiatAmountFormatted: String {
        switch fiatAmountState {
        case .idle:
            return ""
        case .loading:
            return "0"
        case .loaded(let value):
            return value.currencyFormatted(code: AppSettings.shared.selectedCurrencyCode)
        case .formatted(let value):
            return value
        }
    }

    init(
        balance: State = .idle,
        canChangeCurrency: Bool,
        cryptoAmountState: State = .idle,
        fiatAmountState: State = .idle,
        tokenIconState: SwappingTokenIconView.State
    ) {
        self.balance = balance
        self.canChangeCurrency = canChangeCurrency
        self.cryptoAmountState = cryptoAmountState
        self.fiatAmountState = fiatAmountState
        self.tokenIconState = tokenIconState
    }

    func update(cryptoAmountState: State) {
        self.cryptoAmountState = cryptoAmountState
    }

    func update(fiatAmountState: State) {
        self.fiatAmountState = fiatAmountState
    }
}

extension ReceiveCurrencyViewModel {
    enum State: Hashable {
        case idle
        case loading
        case formatted(_ value: String)

        @available(*, deprecated, renamed: "formatted", message: "Have to be formatted outside")
        case loaded(_ value: Decimal)
    }
}
