//
//  DustRestrictable.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 12.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol DustRestrictable {
    var dustValue: Amount { get }

    func validateDust(amount: Amount, fee: Amount) throws
}

extension DustRestrictable where Self: WalletProvider {
    func validateDust(amount: Amount, fee: Amount) throws {
        guard dustValue.type == amount.type else {
            return
        }

        guard let balance = wallet.amounts[amount.type] else {
            throw ValidationError.balanceNotFound
        }

        if amount < dustValue {
            throw ValidationError.dustAmount(minimumAmount: dustValue)
        }

        // Total amount which will be spend
        var total = amount.value

        if amount.type == fee.type {
            total += fee.value
        }

        let change = balance.value - total
        if change > 0, change < dustValue.value {
            throw ValidationError.dustChange(minimumAmount: dustValue)
        }
    }
}
