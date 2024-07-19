//
//  StakingAPIProvider.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 27.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol StakingAPIProvider {
    func enabledYields() async throws -> [YieldInfo]
    func yield(integrationId: String) async throws -> YieldInfo
    func balance(wallet: StakingWallet) async throws -> StakingBalanceInfo?

    func enterAction(amount: Decimal, address: String, validator: String, integrationId: String) async throws -> EnterAction

    func transaction(id: String) async throws -> TransactionInfo
    func patchTransaction(id: String) async throws -> TransactionInfo
    func submitTransaction(hash: String, signedTransaction: String) async throws
    func submitHash(hash: String, transactionId: String) async throws
}
