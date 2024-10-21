//
//  BitcoinFeeParameters.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 16.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct BitcoinFeeParameters: FeeParameters {
    /// Fee rate per byte in satoshi
    public let rate: Int

    public init(rate: Int) {
        self.rate = rate
    }
}
