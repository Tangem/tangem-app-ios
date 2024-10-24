//
//  ExistentialDepositProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 29.02.2024.
//

import Foundation

public protocol ExistentialDepositProvider {
    var existentialDeposit: Amount { get }
}
