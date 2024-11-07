//
//  MinimumAmountRestrictable.swift
//  BlockchainSdk
//
//  Created by Alexander Skibin on 03.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol MinimumAmountRestrictable {
    var minimumAmountRestrictValue: Amount { get }

    func validateMinimumRestrictAmount(amount: Amount, fee: Amount) throws
}

extension MinimumAmountRestrictable where Self: WalletProvider {
    func validateMinimumRestrictAmount(amount: Amount, fee: Amount) throws {
        if amount < minimumAmountRestrictValue {
            throw ValidationError.minimumRestrictAmount(minimumAmount: minimumAmountRestrictValue)
        }
    }
}
