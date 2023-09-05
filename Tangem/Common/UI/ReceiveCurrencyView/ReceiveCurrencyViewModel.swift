//
//  ReceiveCurrencyViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 17.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct ReceiveCurrencyViewModel: Identifiable {
    var id: Int { hashValue }

    private(set) var canChangeCurrency: Bool
    private(set) var cryptoAmountState: State
    private(set) var fiatAmountState: State

    let tokenIcon: SwappingTokenIconViewModel

    var balanceString: String {
        (balance ?? 0).groupedFormatted()
    }

    var cryptoAmountFormatted: String {
        cryptoAmountState.value?.groupedFormatted() ?? "0"
    }

    var fiatAmountFormatted: String {
        fiatAmountState.value?.currencyFormatted(code: AppSettings.shared.selectedCurrencyCode) ?? "0"
    }

    private let balance: Decimal?

    init(
        balance: Decimal?,
        canChangeCurrency: Bool,
        cryptoAmountState: State,
        fiatAmountState: State,
        tokenIcon: SwappingTokenIconViewModel
    ) {
        self.balance = balance
        self.canChangeCurrency = canChangeCurrency
        self.cryptoAmountState = cryptoAmountState
        self.fiatAmountState = fiatAmountState
        self.tokenIcon = tokenIcon
    }

    mutating func update(cryptoAmountState: State) {
        self.cryptoAmountState = cryptoAmountState
    }

    mutating func update(fiatAmountState: State) {
        self.fiatAmountState = fiatAmountState
    }
}

extension ReceiveCurrencyViewModel {
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

extension ReceiveCurrencyViewModel: Hashable {
    static func == (lhs: ReceiveCurrencyViewModel, rhs: ReceiveCurrencyViewModel) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(cryptoAmountState)
        hasher.combine(fiatAmountState)
        hasher.combine(tokenIcon)
    }
}
