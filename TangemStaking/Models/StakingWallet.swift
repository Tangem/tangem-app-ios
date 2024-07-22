//
//  StakingWallet.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 24.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct StakingWallet: Hashable {
    public let item: StakingTokenItem
    public let address: String

    public init(item: StakingTokenItem, address: String) {
        self.item = item
        self.address = address
    }
}
