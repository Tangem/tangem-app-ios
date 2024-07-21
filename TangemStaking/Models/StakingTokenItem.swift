//
//  StakingTokenItem.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 15.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct StakingTokenItem: Hashable {
    public let coinId: String
    public let contractAdress: String?

    public init(coinId: String, contractAdress: String?) {
        self.coinId = coinId
        self.contractAdress = contractAdress
    }
}
