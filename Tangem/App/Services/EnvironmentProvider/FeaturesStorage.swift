//
//  FeatureStorage.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Provider

class FeatureStorage {
    @AppStorageCompat(FeatureStorageKeys.testnet)
    var isTestnet: Bool = false

    @AppStorageCompat(FeatureStorageKeys.availableFeatures)
    var availableFeatures: [Feature: FeatureState] = [:]

    @AppStorageCompat(FeatureStorageKeys.useDevApi)
    var useDevApi = false

    // TODO: Remove after transaction history implementation in BlockchainSDK
    @AppStorageCompat(FeatureStorageKeys.fakeTxHistory)
    var useFakeTxHistory = false

    @AppStorageCompat(FeatureStorageKeys.supportedBlockchainsIds)
    var supportedBlockchainsIds: [String] = []
}

// MARK: - Keys

private enum FeatureStorageKeys: String {
    case testnet
    case availableFeatures = "integrated_features"
    case useDevApi = "use_dev_api"
    case fakeTxHistory = "fake_transaction_history"
    case supportedBlockchainsIds
}
