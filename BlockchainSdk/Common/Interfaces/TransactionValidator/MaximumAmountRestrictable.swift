//
//  MaximumAmountRestrictable.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 29.02.2024.
//

import Foundation

protocol MaximumAmountRestrictable {
    func validateMaximumAmount(amount: Amount, fee: Amount) throws
}
