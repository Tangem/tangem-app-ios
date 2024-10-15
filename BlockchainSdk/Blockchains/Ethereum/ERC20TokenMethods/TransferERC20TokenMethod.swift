//
//  TransferERC20SmartContractMethod.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 15.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

/// https://eips.ethereum.org/EIPS/eip-20#transfer
public struct TransferERC20TokenMethod {
    public let destination: String
    public let amount: BigUInt
    
    public init(destination: String, amount: BigUInt) {
        self.amount = amount
        self.destination = destination
    }
}

// MARK: - SmartContractMethod

extension TransferERC20TokenMethod: SmartContractMethod {
    public var prefix: String { "0xa9059cbb" }

    public var data: Data {
        let prefixData = Data(hexString: prefix)
        let addressData = Data(hexString: destination).leadingZeroPadding(toLength: 32)
        let amountData = amount.serialize().leadingZeroPadding(toLength: 32)
        return prefixData + addressData + amountData
    }
}
