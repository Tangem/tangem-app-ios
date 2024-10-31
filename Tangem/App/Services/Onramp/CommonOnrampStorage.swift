//
//  CommonOnrampStorage.swift
//  TangemApp
//
//  Created by Sergey Balashov on 21.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemExpress
import TangemFoundation

struct CommonOnrampStorage: OnrampStorage {
    @Injected(\.persistentStorage) private var storage: PersistentStorageProtocol

    func save(preference: OnrampUserPreference) {
        do {
            try storage.store(value: preference, for: .onrampPreference)
        } catch {
            AppLog.shared.debug("[CommonOnrampStorage] Failed to save changes in storage. Reason: \(error)")
        }
    }

    func preference() -> OnrampUserPreference? {
        do {
            return try storage.value(for: .onrampPreference)
        } catch {
            AppLog.shared.debug("[CommonOnrampStorage] Couldn't get the staking transactions list from the storage with error \(error)")
            return nil
        }
    }
}
