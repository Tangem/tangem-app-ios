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
            // We have to specify `networks` because on devices that
            // support making payments but don’t have any payment cards configured,
            // the `canMakePayments()` method returns true because
            // the hardware and parental controls allow making payments
            return PKPaymentAuthorizationViewController.canMakePayments(
                usingNetworks: [.visa, .masterCard]
            )
        }

        return true
    }
}
