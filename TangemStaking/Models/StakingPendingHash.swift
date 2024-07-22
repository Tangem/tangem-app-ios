//
//  StakingPendingHash.swift
//  TangemStaking
//
//  Created by Alexander Osokin on 12.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct StakingPendingHash {
    public let transactionId: String
    public let hash: String

    public init(transactionId: String, hash: String) {
        self.transactionId = transactionId
        self.hash = hash
    }
}
