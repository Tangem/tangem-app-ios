//
//  OnrampPaymentMethodsInputOutput.swift
//  TangemApp
//
//  Created by Sergey Balashov on 31.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

protocol OnrampPaymentMethodsInput: AnyObject {
    var selectedOnrampPaymentMethod: OnrampPaymentMethod? { get }
    var selectedOnrampPaymentMethodPublisher: AnyPublisher<OnrampPaymentMethod?, Never> { get }
}

protocol OnrampPaymentMethodsOutput: AnyObject {
    func userDidSelect(paymentMethod: OnrampPaymentMethod)
}
