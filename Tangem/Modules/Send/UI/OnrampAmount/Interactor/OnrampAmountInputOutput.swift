//
//  OnrampAmountInputOutput.swift
//  TangemApp
//
//  Created by Sergey Balashov on 30.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

protocol OnrampAmountInput: AnyObject {
    var fiatCurrency: LoadingValue<OnrampFiatCurrency> { get }
    var currencyPublisher: AnyPublisher<LoadingValue<OnrampFiatCurrency>, Never> { get }
}

protocol OnrampAmountOutput: AnyObject {
    func amountDidChanged(amount: SendAmount?)
}
