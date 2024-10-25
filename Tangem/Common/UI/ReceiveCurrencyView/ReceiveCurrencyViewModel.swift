//
//  ReceiveCurrencyViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 17.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress

class ReceiveCurrencyViewModel: ObservableObject, Identifiable {
    @Published private(set) var expressCurrencyViewModel: ExpressCurrencyViewModel
    @Published private(set) var cryptoAmountState: LoadableTextView.State

    private(set) var expectAmount: Decimal = 0
    private(set) var expectAmountDecimals: Int = 0

    init(
        expressCurrencyViewModel: ExpressCurrencyViewModel,
        cryptoAmountState: LoadableTextView.State = .initialized
    ) {
        self.expressCurrencyViewModel = expressCurrencyViewModel
        self.cryptoAmountState = cryptoAmountState
    }

    func update(wallet: LoadingValue<WalletModel>, initialWalletId: Int) {
        expressCurrencyViewModel.update(wallet: wallet, initialWalletId: initialWalletId)
    }

    func updateFiatValue(expectAmount: Decimal?, tokenItem: TokenItem?) {
        expressCurrencyViewModel.updateFiatValue(expectAmount: expectAmount, tokenItem: tokenItem)

        guard let expectAmount else {
            update(cryptoAmountState: .loaded(text: "0"))
            self.expectAmount = 0
            expectAmountDecimals = 0
            return
        }

        self.expectAmount = expectAmount

        let decimals = tokenItem?.decimalCount ?? AppConstants.maximumFractionDigitsForBalance
        expectAmountDecimals = decimals

        let formatter = DecimalNumberFormatter(maximumFractionDigits: decimals)
        let formatted: String = formatter.format(value: expectAmount)
        update(cryptoAmountState: .loaded(text: formatted))
    }

    func update(cryptoAmountState: LoadableTextView.State) {
        self.cryptoAmountState = cryptoAmountState
    }
}

extension ReceiveCurrencyViewModel {
    enum State: Hashable {
        case idle
        case loading
        case formatted(_ value: String)
    }
}
