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
    public let publicKey: Data

    public init(item: StakingTokenItem, address: String, publicKey: Data) {
        self.item = item
        self.address = address
        self.publicKey = publicKey
    }
}
