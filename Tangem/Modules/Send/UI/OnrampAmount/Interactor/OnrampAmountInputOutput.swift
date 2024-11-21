//
//  OnrampAmountInputOutput.swift
//  TangemApp
//
//  Created by Sergey Balashov on 30.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress
import TangemFoundation

protocol OnrampAmountInput: AnyObject {
    var fiatCurrency: LoadingResult<OnrampFiatCurrency, Error> { get }
    var fiatCurrencyPublisher: AnyPublisher<LoadingResult<OnrampFiatCurrency, Error>, Never> { get }

    var amountPublisher: AnyPublisher<SendAmount?, Never> { get }
}

protocol OnrampAmountOutput: AnyObject {
    func amountDidChanged(amount: SendAmount?)
}
