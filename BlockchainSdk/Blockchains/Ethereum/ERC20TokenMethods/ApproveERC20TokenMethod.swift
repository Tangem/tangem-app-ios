//
//  ApproveERC20TokenMethod.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 15.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

/// https://eips.ethereum.org/EIPS/eip-20#approve
public struct ApproveERC20TokenMethod {
    let spender: String
    let amount: BigUInt

    public init(spender: String, amount: BigUInt) {
        self.spender = spender
        self.amount = amount
    }
}

// MARK: - SmartContractMethod

extension ApproveERC20TokenMethod: SmartContractMethod {
    public var prefix: String { "0x095ea7b3" }

    public var data: Data {
        let prefixData = Data(hexString: prefix)
        let spenderData = Data(hexString: spender).leadingZeroPadding(toLength: 32)
        let amountData = amount.serialize().leadingZeroPadding(toLength: 32)
        return prefixData + spenderData + amountData
    }
}
