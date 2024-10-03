//
//  CommonStakingPendingHashesRepository.swift
//  Tangem
//
//  Created by Alexander Osokin on 12.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

class CommonStakingPendingHashesRepository: StakingPendingHashesRepository {
    @AppStorageCompat(StorageKeys.pendingHashes)
    private var pendingHashes: [String: String] = [:]

    func storeHash(_ hash: StakingPendingHash) {
        var hashes = pendingHashes
        hashes[hash.transactionId] = hash.hash
        pendingHashes = hashes
    }

    func fetchHashes() -> [StakingPendingHash] {
        return pendingHashes.map { StakingPendingHash(transactionId: $0.key, hash: $0.value) }
    }

    func removeHash(_ hash: StakingPendingHash) {
        var hashes = pendingHashes
        hashes[hash.transactionId] = nil
        pendingHashes = hashes
    }
}

// MARK: - Constants

private extension CommonStakingPendingHashesRepository {
    enum StorageKeys: String, RawRepresentable {
        case pendingHashes = "tangem_staking_pending_hashes"
    }
}
