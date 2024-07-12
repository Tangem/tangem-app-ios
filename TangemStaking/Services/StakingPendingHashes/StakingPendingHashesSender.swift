//
//  StakingPendingHashesSender.swift
//  TangemStaking
//
//  Created by Alexander Osokin on 12.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol StakingPendingHashesSender {
    func sendHash(_ pendingHash: StakingPendingHash) async throws

    func sendHashesIfNeeded()
}
