//
//  TronFeeParameters.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 11.09.2024.
//

import Foundation

public struct TronFeeParameters: FeeParameters {
    public let energySpent: Int
    public let energyFullyCoversFee: Bool
}
