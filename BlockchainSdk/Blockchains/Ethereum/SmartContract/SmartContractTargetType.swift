//
//  SmartContractMethodType.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 15.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol SmartContractTargetType {
    var contactAddress: String { get }
    var methodName: String { get }
    var parameters: [SmartContractMethodParameterType] { get }
}
