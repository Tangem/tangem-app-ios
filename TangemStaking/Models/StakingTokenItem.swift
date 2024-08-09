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

    public init(network: StakeKitNetworkType, contractAddress: String?) {
        self.network = network
        self.contractAddress = contractAddress
    }
}
