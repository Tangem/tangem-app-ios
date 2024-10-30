//
//  OnrampInputOutput.swift
//  TangemApp
//
//  Created by Sergey Balashov on 18.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

protocol OnrampInput: AnyObject {
    var currencyPublisher: AnyPublisher<OnrampFiatCurrency, Never> { get }
    var isLoadingRatesPublisher: AnyPublisher<Bool, Never> { get }
    var selectedQuotePublisher: AnyPublisher<OnrampQuote?, Never> { get }
}

protocol OnrampOutput: AnyObject {}
