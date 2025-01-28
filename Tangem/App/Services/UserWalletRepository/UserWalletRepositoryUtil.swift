//
//  UserWalletRepositoryUtil.swift
//  Tangem
//
//  Created by Andrey Chukavin on 19.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import TangemSdk

class UserWalletRepositoryUtil {
    private var fileManager: FileManager {
        FileManager.default
    }

    private var userWalletDirectoryUrl: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("user_wallets", isDirectory: true)
    }

    private let publicDataEncryptionKeyStorageKey = "user_wallet_public_data_encryption_key"

    func removePublicDataEncryptionKey() {
        do {
            let secureStorage = SecureStorage()
            try secureStorage.delete(publicDataEncryptionKeyStorageKey)
        } catch {
            AppLog.error("Failed to erase public data encryption key", error: error)
        }
    }

    func savedUserWallets(encryptionKeyByUserWalletId: [UserWalletId: UserWalletEncryptionKey]) -> [StoredUserWallet] {
        do {
            guard fileManager.fileExists(atPath: userWalletListPath().path) else {
                AppLog.warning("Detected empty saved user wallets")
                return []
            }

            let decoder = JSONDecoder.tangemSdkDecoder

            let userWalletsPublicDataEncrypted = try Data(contentsOf: userWalletListPath())
            let userWalletsPublicData = try decrypt(userWalletsPublicDataEncrypted, with: publicDataEncryptionKey())
            var userWallets = try decoder.decode([StoredUserWallet].self, from: userWalletsPublicData)

            for i in 0 ..< userWallets.count {
                let userWallet = userWallets[i]
                let userWalletId = UserWalletId(value: userWallet.userWalletId)
                guard let userWalletEncryptionKey = encryptionKeyByUserWalletId[userWalletId] else {
                    continue
                }

                let sensitiveInformationEncryptedData = try Data(contentsOf: userWalletPath(for: userWalletId))
                let sensitiveInformationData = try decrypt(sensitiveInformationEncryptedData, with: userWalletEncryptionKey)
                let sensitiveInformation = try decoder.decode(StoredUserWallet.SensitiveInformation.self, from: sensitiveInformationData)

                var card = userWallet.card
                card.wallets = sensitiveInformation.wallets
                userWallets[i].card = card
            }

            return userWallets
        } catch {
            AppLog.error(error: error)
            return []
        }
    }

    func saveUserWallets(_ userWallets: [StoredUserWallet]) {
        let encoder = JSONEncoder.tangemSdkEncoder

        do {
            if userWallets.isEmpty {
                if fileManager.fileExists(atPath: userWalletDirectoryUrl.path) {
                    try fileManager.removeItem(at: userWalletDirectoryUrl)
                }
                return
            }

            try fileManager.createDirectory(at: userWalletDirectoryUrl, withIntermediateDirectories: true)

            let userWalletsWithoutSensitiveInformation: [StoredUserWallet] = userWallets.map {
                var card = $0.card
                card.wallets = []

                var userWalletWithoutKeys = $0
                userWalletWithoutKeys.card = card
                return userWalletWithoutKeys
            }

            let publicData = try encoder.encode(userWalletsWithoutSensitiveInformation)
            let publicDataEncoded = try encrypt(publicData, with: publicDataEncryptionKey())
            try publicDataEncoded.write(to: userWalletListPath(), options: .atomic)
            try excludeFromBackup(url: userWalletListPath())

            for userWallet in userWallets {
                guard let encryptionKey = UserWalletEncryptionKeyFactory().encryptionKey(for: userWallet) else {
                    AppLog.error(error: "User wallet failed to generate encryption key")
                    continue
                }

                let sensitiveInformation = StoredUserWallet.SensitiveInformation(wallets: userWallet.card.wallets)
                let sensitiveDataEncoded = try encrypt(encoder.encode(sensitiveInformation), with: encryptionKey)
                let sensitiveDataPath = userWalletPath(for: UserWalletId(value: userWallet.userWalletId))
                try sensitiveDataEncoded.write(to: sensitiveDataPath, options: .atomic)
                try excludeFromBackup(url: sensitiveDataPath)
            }
            AppLog.info("User wallets were saved successfully")
        } catch {
            AppLog.error("Failed to save user wallets", error: error)
        }
    }

    private func publicDataEncryptionKey() throws -> UserWalletEncryptionKey {
        let secureStorage = SecureStorage()

        let encryptionKeyData = try secureStorage.get(publicDataEncryptionKeyStorageKey)
        if let encryptionKeyData = encryptionKeyData {
            let symmetricKey: SymmetricKey = .init(data: encryptionKeyData)
            return UserWalletEncryptionKey(symmetricKey: symmetricKey)
        }

        let newEncryptionKey = SymmetricKey(size: .bits256)
        try secureStorage.store(newEncryptionKey.dataRepresentationWithHexConversion, forKey: publicDataEncryptionKeyStorageKey)
        return UserWalletEncryptionKey(symmetricKey: newEncryptionKey)
    }

    private func userWalletListPath() -> URL {
        userWalletDirectoryUrl.appendingPathComponent("user_wallets.bin")
    }

    private func userWalletPath(for userWalletId: UserWalletId) -> URL {
        return userWalletDirectoryUrl.appendingPathComponent("user_wallet_\(userWalletId.stringValue.lowercased()).bin")
    }

    private func excludeFromBackup(url originalUrl: URL) throws {
        var url = originalUrl

        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try url.setResourceValues(resourceValues)
    }

    private func decrypt(_ data: Data, with key: UserWalletEncryptionKey) throws -> Data {
        let sealedBox = try ChaChaPoly.SealedBox(combined: data)
        let decryptedData = try ChaChaPoly.open(sealedBox, using: key.symmetricKey)
        return decryptedData
    }

    private func encrypt(_ data: Data, with key: UserWalletEncryptionKey) throws -> Data {
        let sealedBox = try ChaChaPoly.seal(data, using: key.symmetricKey)
        let sealedData = sealedBox.combined
        return sealedData
    }
}
