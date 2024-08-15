//
//  StakingTokenItem.swift
//  TangemStaking
//
//  Created by Dmitry Fedorov on 15.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct StakingTokenItem: Hashable {
    public let network: StakeKitNetworkType
    public let contractAddress: String?

    public init(network: StakeKitNetworkType, contractAddress: String? = nil) {
        self.network = network
        self.contractAddress = contractAddress
    }
}
