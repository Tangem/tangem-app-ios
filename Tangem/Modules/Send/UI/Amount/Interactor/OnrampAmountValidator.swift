//
//  OnrampAmountValidator.swift
//  TangemApp
//
//  Created by Sergey Balashov on 18.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct OnrampAmountValidator: SendAmountValidator {
    func validate(amount: Decimal) throws {
        // User can buy any amount which wants
    }
}
