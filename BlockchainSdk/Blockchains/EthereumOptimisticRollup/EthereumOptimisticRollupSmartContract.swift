//
//  EthereumOptimisticRollupSmartContract.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 16.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum EthereumOptimisticRollupSmartContract: SmartContractTargetType {
    case getL1Fee(data: Data)
    case getL1GasUsed(data: Data)
    case l1BaseFee

    public var contactAddress: String { "0x420000000000000000000000000000000000000F" }

    public var methodName: String {
        switch self {
        case .getL1Fee:
            return "getL1Fee"
        case .getL1GasUsed:
            return "getL1GasUsed"
        case .l1BaseFee:
            return "l1BaseFee"
        }
    }

    public var parameters: [SmartContractMethodParameterType] {
        switch self {
        case .getL1Fee(let data):
            return [.bytes(data)]
        case .getL1GasUsed(let data):
            return [.bytes(data)]
        case .l1BaseFee:
            return []
        }
    }
}
