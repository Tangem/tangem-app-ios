//
//  CardanoFeeParameters.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 03.07.2024.
//

import Foundation

struct CardanoFeeParameters: FeeParameters {
    let adaValue: UInt64
    let change: UInt64
    let useMaxAmount: Bool
}
