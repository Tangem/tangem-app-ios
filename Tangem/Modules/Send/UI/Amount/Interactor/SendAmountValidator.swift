//
//  SendAmountValidator.swift
//  Tangem
//
//  Created by Sergey Balashov on 13.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol SendAmountValidator {
    func validate(amount: Decimal) throws
}

struct CommonSendAmountValidator {
    private let tokenItem: TokenItem
    private let validator: TransactionValidator

    init(tokenItem: TokenItem, validator: TransactionValidator) {
        self.tokenItem = tokenItem
        self.validator = validator
    }
}

extension CommonSendAmountValidator: SendAmountValidator {
    func validate(amount: Decimal) throws {
        let amount = Amount(with: tokenItem.blockchain, type: tokenItem.amountType, value: amount)
        try validator.validate(amount: amount)
    }
}
