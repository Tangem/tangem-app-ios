//
//  UserDefaultsBlockchainDataStorage.swift
//  Tangem
//
//  Created by Andrey Fedorov on 14.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct UserDefaultsBlockchainDataStorage {
    private let suiteName: String?
    private var userDefaults: UserDefaults { UserDefaults(suiteName: suiteName) ?? .standard }

    init(suiteName: String? = nil) {
        self.suiteName = suiteName
    }
}

// MARK: - BlockchainDataStorage protocol conformance

extension UserDefaultsBlockchainDataStorage: BlockchainDataStorage {
    func get<BlockchainData>(key: String) async -> BlockchainData? where BlockchainData: Decodable {
        return await Task {
            guard let data = userDefaults.data(forKey: key) else {
                return nil
            }

            guard let value = try? JSONDecoder().decode(BlockchainData.self, from: data) else {
                AppLog.warning("Unable to deserialize stored value for key '\(key)'")
                return nil
            }

            return value
        }.value
    }

    func store<BlockchainData>(key: String, value: BlockchainData?) async where BlockchainData: Encodable {
        Task {
            guard let value else {
                // Removing existing stored data for a given key if a `nil` value is received
                userDefaults.removeObject(forKey: key)
                return
            }

            guard let data = try? JSONEncoder().encode(value) else {
                AppLog.warning("Unable to serialize given value of type '\(BlockchainData.self)' for key '\(key)'")
                return
            }

            userDefaults.setValue(data, forKey: key)
        }
    }
}
