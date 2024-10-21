//
//  SmartContractMethod.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 15.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol SmartContractMethod {
    var prefix: String { get }
    var data: Data { get }
}

public extension SmartContractMethod {
    /// The hex data with the `0x` prefix. Use it for send as `data` in the `eth_call`
    var encodedData: String {
        data.hexString.addHexPrefix()
    }
}
