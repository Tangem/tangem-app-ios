//
//  ReserveAmountRestrictable.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 12.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol ReserveAmountRestrictable {
    func validateReserveAmount(amount: Amount, addressType: ReserveAmountRestrictableAddressType) async throws
}

enum ReserveAmountRestrictableAddressType {
    /// The specified address will be used for verification
    case address(String)
    /// It will be considered as an absolute brand new address for verification
    case notCreated
}
