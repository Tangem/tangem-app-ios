//
//  StakingTokenItem.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 15.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct StakingTokenItem: Hashable {
    public let network: StakeKitNetworkType
    public let contractAddress: String?
    public let name: String
    public let decimals: Int
    public let symbol: String

    public init(
        network: StakeKitNetworkType,
        contractAddress: String? = nil,
        name: String,
        decimals: Int,
        symbol: String
    ) {
        self.network = network
        self.contractAddress = contractAddress
        self.name = name
        self.decimals = decimals
        self.symbol = symbol
    }
}
