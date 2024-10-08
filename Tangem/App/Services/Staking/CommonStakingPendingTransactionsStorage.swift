//
//  CommonStakingPendingTransactionsStorage.swift
//  TangemApp
//
//  Created by Sergey Balashov on 12.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemStaking
import TangemFoundation

struct CommonStakingPendingTransactionsStorage: StakingPendingTransactionsStorage {
    @Injected(\.persistentStorage) private var storage: PersistentStorageProtocol

    func save(records: Set<TangemStaking.StakingPendingTransactionRecord>) {
        do {
            try storage.store(value: records, for: .pendingStakingTransactions)
        } catch {
            AppLog.shared.debug("[StakingPendingTransactionsStorage] Failed to save changes in storage. Reason: \(error)")
        }
    }

    func loadRecords() -> Set<TangemStaking.StakingPendingTransactionRecord> {
        do {
            return try storage.value(for: .pendingStakingTransactions) ?? []
        } catch {
            AppLog.shared.debug("[StakingPendingTransactionsStorage] Couldn't get the staking transactions list from the storage with error \(error)")
            return []
        }
    }
}
