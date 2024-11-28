//
//  OnrampPaymentMethodsFilter.swift
//  TangemApp
//
//  Created by Sergey Balashov on 28.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import PassKit

struct OnrampPaymentMethodsFilter {
    func isSupported(paymentMethod: OnrampPaymentMethod) -> Bool {
        if paymentMethod.type == .googlePay {
            return false
        }

        if paymentMethod.type == .applePay {
            return PKPaymentAuthorizationViewController.canMakePayments()
        }

        return true
    }
}
