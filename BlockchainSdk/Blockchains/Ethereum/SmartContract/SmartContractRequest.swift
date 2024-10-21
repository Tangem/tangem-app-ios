//
//  SmartContractRequest.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 17/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol SmartContractRequest {
    var contractAddress: String { get }
    var encodedData: String { get }
}
