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
    var fiatCurrency: LoadingResult<OnrampFiatCurrency, Never> { get }
    var fiatCurrencyPublisher: AnyPublisher<LoadingResult<OnrampFiatCurrency, Never>, Never> { get }
}

protocol OnrampAmountOutput: AnyObject {
    func amountDidChanged(fiat: Decimal?)
}
