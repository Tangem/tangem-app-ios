//
//  FakeBlockchainDataStorage.swift
//  Tangem
//
//  Created by Andrey Fedorov on 14.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

final class FakeBlockchainDataStorage: BlockchainDataStorage {
    private var storage: [String: Any] = [:]

    func get<BlockchainData>(key: String) async -> BlockchainData? where BlockchainData: Decodable {
        return storage[key] as? BlockchainData
    }

    func store<BlockchainData>(key: String, value: BlockchainData?) async where BlockchainData: Encodable {
        storage[key] = value
    }
}
