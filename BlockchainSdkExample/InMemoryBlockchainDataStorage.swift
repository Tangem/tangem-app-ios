//
//  InMemoryBlockchainDataStorage.swift
//  BlockchainSdkExample
//
//  Created by Andrey Fedorov on 13.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

final class InMemoryBlockchainDataStorage: BlockchainDataStorage {
    typealias StorageOverride = () -> Any?

    private let storageOverride: StorageOverride
    private var storage: [String: Any] = [:]

    init(
        storageOverride: @escaping StorageOverride
    ) {
        self.storageOverride = storageOverride
    }

    func get<BlockchainData>(key: String) async -> BlockchainData? where BlockchainData: Decodable {
        if let overriddenValue = storageOverride() as? BlockchainData {
            return overriddenValue
        }

        return storage[key] as? BlockchainData
    }
    
    func store<BlockchainData>(key: String, value: BlockchainData?) async where BlockchainData: Encodable {
        storage[key] = value
    }
}
