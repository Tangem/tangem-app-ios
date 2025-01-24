//
//  SendCurrencyViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 17.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class SendCurrencyViewModel: ObservableObject, Identifiable {
    @Published private(set) var expressCurrencyViewModel: ExpressCurrencyViewModel
    @Published private(set) var decimalNumberTextFieldViewModel: DecimalNumberTextField.ViewModel

    init(
        expressCurrencyViewModel: ExpressCurrencyViewModel,
        decimalNumberTextFieldViewModel: DecimalNumberTextField.ViewModel
    ) {
        self.expressCurrencyViewModel = expressCurrencyViewModel
        self.decimalNumberTextFieldViewModel = decimalNumberTextFieldViewModel
    }

    func textFieldDidTapped() {
        Analytics.log(.swapSendTokenBalanceClicked)
    }

    func update(wallet: WalletModel, initialWalletId: WalletModelId) {
        expressCurrencyViewModel.update(wallet: .loaded(wallet), initialWalletId: initialWalletId)
        decimalNumberTextFieldViewModel.update(maximumFractionDigits: wallet.decimalCount)
    }

    func updateSendFiatValue(amount: Decimal?, tokenItem: TokenItem) {
        expressCurrencyViewModel.updateFiatValue(expectAmount: amount, tokenItem: tokenItem)
    }
}
