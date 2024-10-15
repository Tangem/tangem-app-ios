//
//  ABIEncoder.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 30.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol ABIEncoder {
    func encode(method: String, parameters: [SmartContractMethodParameterType]) -> String
}
