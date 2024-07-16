//
//  CommonStakingManager.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 28.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class CommonStakingManager {
    private let wallet: StakingWallet
    private let yieldInfo: YieldInfo
    private let balanceProvider: StakingBalanceProvider
    private let apiProvider: StakingAPIProvider
    private let logger: Logger

    init(
        wallet: StakingWallet,
        yieldInfo: YieldInfo,
        balanceProvider: StakingBalanceProvider,
        apiProvider: StakingAPIProvider,
        logger: Logger
    ) {
        self.wallet = wallet
        self.yieldInfo = yieldInfo
        self.balanceProvider = balanceProvider
        self.apiProvider = apiProvider
        self.logger = logger
    }
}

// MARK: - StakingManager

extension CommonStakingManager: StakingManager {
    var yield: YieldInfo { yieldInfo }
    var balance: StakingBalanceInfo? { balanceProvider.balance }

    var balancePublisher: AnyPublisher<StakingBalanceInfo?, Never> {
        balanceProvider.balancePublisher
    }

    func updateBalance() {
        balanceProvider.updateBalance()
    }

    func getFee(amount: Decimal, validator: String) async throws -> Decimal {
        let action = try await apiProvider.enterAction(
            amount: amount,
            address: wallet.address,
            validator: validator,
            integrationId: yieldInfo.id
        )

        let transactionId = action.transactions[action.currentStepIndex].id
        let transaction = try await apiProvider.patchTransaction(id: transactionId)

        return transaction.fee
    }

    func getTransaction() async throws {
        // TBD: https://tangem.atlassian.net/browse/IOS-6897
    }
}

public enum StakingManagerError: Error {
    case notFound
}
