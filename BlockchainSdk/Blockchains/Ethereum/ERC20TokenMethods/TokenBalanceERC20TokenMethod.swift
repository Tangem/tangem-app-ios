//
//  TokenBalanceERC20TokenMethod.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 09.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// https://eips.ethereum.org/EIPS/eip-20#balanceof
public struct TokenBalanceERC20TokenMethod {
    let owner: String

    public init(owner: String) {
        self.owner = owner
    }
}

// MARK: - SmartContractMethod

extension TokenBalanceERC20TokenMethod: SmartContractMethod {
    public var prefix: String { "0x70a08231" }

    public var data: Data {
        let prefixData = Data(hexString: prefix)
        let ownerData = Data(hexString: owner).leadingZeroPadding(toLength: 32)
        return prefixData + ownerData
    }
}
