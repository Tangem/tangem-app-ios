//
//  FeeIncludedCalculator.swift
//  Tangem
//
//  Created by Sergey Balashov on 19.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol FeeIncludedCalculator {
    func shouldIncludeFee(_ fee: Fee, into amount: Amount) -> Bool
}
