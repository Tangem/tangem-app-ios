//
//  CommonStakeKitTransactionStatusProvider.swift
//  TangemApp
//
//  Created by Dmitry Fedorov on 29.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import BlockchainSdk

final class CommonStakeKitTransactionStatusProvider: StakeKitTransactionStatusProvider {
    private let stakingManager: StakingManager

    init(stakingManager: StakingManager) {
        self.stakingManager = stakingManager
    }

    func transactionStatus(_ transaction: StakeKitTransaction) async throws -> StakeKitTransaction.Status? {
        let transactionInfo = try await stakingManager.transactionDetails(id: transaction.id)
        return StakeKitTransaction.Status(rawValue: transactionInfo.status)
    }
}
