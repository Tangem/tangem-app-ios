//
//  CommonAnalyticsContext.swift
//  Tangem
//
//  Created by Alexander Osokin on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

class CommonAnalyticsContext: AnalyticsContext {
    private(set) var contextData: AnalyticsContextData?

    private var analyticsStorage = AnalyticsStorage()

    init() {}

    func setupContext(with contextData: AnalyticsContextData) {
        self.contextData = contextData
    }

    func clearContext() {
        contextData = nil
    }

    func value(forKey: AnalyticsStorageKey, scope: AnalyticsContextScope) -> Any? {
        guard let id = makeId(for: scope) else { return nil }

        return analyticsStorage.value(forKey, id: id)
    }

    func set(value: Any, forKey storageKey: AnalyticsStorageKey, scope: AnalyticsContextScope) {
        guard let id = makeId(for: scope) else { return }

        analyticsStorage.set(value, storageKey: storageKey, id: id)
    }

    func removeValue(forKey storageKey: AnalyticsStorageKey, scope: AnalyticsContextScope) {
        guard let id = makeId(for: scope) else { return }

        analyticsStorage.removeValue(storageKey, id: id)
    }

    private func makeId(for scope: AnalyticsContextScope) -> String? {
        switch scope {
        case .userWallet:
            return contextData?.id
        case .common:
            return Constants.commonContextId
        }
    }
}

// MARK: - Constants

private extension CommonAnalyticsContext {
    enum Constants {
        static let commonContextId = "Common"
    }
}

// MARK: - AnalyticsStorage

private class AnalyticsStorage {
    private var tempStorage: [String: Any] = [:]

    func value(_ storageKey: AnalyticsStorageKey, id: String) -> Any? {
        let rawKey = makeRawKey(from: storageKey, id: id)

        if storageKey.isPermanent {
            return UserDefaults.standard.value(forKey: rawKey)
        } else {
            return tempStorage[rawKey]
        }
    }

    func set(_ value: Any, storageKey: AnalyticsStorageKey, id: String) {
        let rawKey = makeRawKey(from: storageKey, id: id)

        if storageKey.isPermanent {
            UserDefaults.standard.set(value, forKey: rawKey)
        } else {
            tempStorage[rawKey] = value
        }
    }

    func removeValue(_ storageKey: AnalyticsStorageKey, id: String) {
        let rawKey = makeRawKey(from: storageKey, id: id)

        if storageKey.isPermanent {
            UserDefaults.standard.removeObject(forKey: rawKey)
        } else {
            tempStorage[rawKey] = nil
        }
    }

    private func makeRawKey(from key: AnalyticsStorageKey, id: String) -> String {
        return "\(id)_\(key.rawValue)"
    }
}
