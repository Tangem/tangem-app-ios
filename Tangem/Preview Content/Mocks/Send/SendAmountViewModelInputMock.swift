//
//  SendAmountViewModelInputMock.swift
//  Tangem
//
//  Created by Andrey Chukavin on 01.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

class SendAmountViewModelInputMock: SendAmountViewModelInput {
    var balance: String {
        "2 130,88 USDT (2 129,92 $)"
    }

    var tokenIconName: String {
        "tether"
    }

    var tokenIconURL: URL? {
        TokenIconURLBuilder().iconURL(id: "tether")
    }

    var tokenIconCustomTokenColor: Color? {
        nil
    }

    var tokenIconBlockchainIconName: String? {
        "ethereum.fill"
    }

    var isCustomToken: Bool {
        false
    }

    var amountFractionDigits: Int {
        2
    }

    var amountAlternativePublisher: AnyPublisher<String, Never> {
        .just(output: "1 000 010,99 USDT")
    }

    var decimalValue: Binding<DecimalNumberTextField.DecimalValue?> {
        .constant(DecimalNumberTextField.DecimalValue.internal(0))
    }

    var walletName: String {
        "Family Wallet"
    }

    var amountError: AnyPublisher<Error?, Never> {
        Just(nil).eraseToAnyPublisher()
    }

    var isFiatCalculation: Bool {
        true
    }

    var cryptoCurrencyCode: String {
        "USDT"
    }

    var fiatCurrencyCode: String {
        "USD"
    }
}
