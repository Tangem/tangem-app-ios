//
//  RentExtemptionRestrictable.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 29.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol RentExtemptionRestrictable {
    var minimalAmountForRentExemption: Amount { get }

    func validateRentExtemption(amount: Amount, fee: Amount) throws
}

extension RentExtemptionRestrictable where Self: WalletProvider {
    func validateRentExtemption(amount: Amount, fee: Amount) throws {
        guard let balance = wallet.amounts[amount.type] else {
            throw ValidationError.balanceNotFound
        }

        var remainingBalance = balance.value

        if amount.type == balance.type {
            remainingBalance -= amount.value
        }

        if fee.type == balance.type {
            remainingBalance -= fee.value
        }

        guard remainingBalance >= 0 else {
            throw ValidationError.totalExceedsBalance
        }

        if remainingBalance > 0, remainingBalance < minimalAmountForRentExemption.value {
            throw ValidationError.remainingAmountIsLessThanRentExtemption(amount: minimalAmountForRentExemption)
        }
    }
}
