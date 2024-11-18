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
    var selectedPaymentMethod: OnrampPaymentMethod? { get }
    var selectedPaymentMethodPublisher: AnyPublisher<OnrampPaymentMethod?, Never> { get }
    var paymentMethodsPublisher: AnyPublisher<[OnrampPaymentMethod], Never> { get }
}

protocol OnrampPaymentMethodsOutput: AnyObject {
    func userDidSelect(paymentMethod: OnrampPaymentMethod)
}
