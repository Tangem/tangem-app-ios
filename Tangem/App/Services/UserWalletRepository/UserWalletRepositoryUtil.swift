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
            AppLog.shared.debug("Failed to erase public data encryption key")
            AppLog.shared.error(error)
        }
    }

    func savedUserWallets(encryptionKeyByUserWalletId: [Data: SymmetricKey]) -> [UserWallet] {
        do {
            guard fileManager.fileExists(atPath: userWalletListPath().path) else {
                AppLog.shared.debug("Detected empty saved user wallets")
                return []
            }

            let decoder = JSONDecoder.tangemSdkDecoder

            let userWalletsPublicDataEncrypted = try Data(contentsOf: userWalletListPath())
            let userWalletsPublicData = try decrypt(userWalletsPublicDataEncrypted, with: publicDataEncryptionKey())
            var userWallets = try decoder.decode([UserWallet].self, from: userWalletsPublicData)

            for i in 0 ..< userWallets.count {
                let userWallet = userWallets[i]

                guard let userWalletEncryptionKey = encryptionKeyByUserWalletId[userWallet.userWalletId] else {
                    continue
                }

                let sensitiveInformationEncryptedData = try Data(contentsOf: userWalletPath(for: userWallet))
                let sensitiveInformationData = try decrypt(sensitiveInformationEncryptedData, with: userWalletEncryptionKey)
                let sensitiveInformation = try decoder.decode(UserWallet.SensitiveInformation.self, from: sensitiveInformationData)

                var card = userWallet.card
                card.wallets = sensitiveInformation.wallets
                userWallets[i].card = card
            }

            return userWallets
        } catch {
            AppLog.shared.error(error)
            return []
        }
    }

    func saveUserWallets(_ userWallets: [UserWallet]) {
        let encoder = JSONEncoder.tangemSdkEncoder

        do {
            if userWallets.isEmpty {
                if fileManager.fileExists(atPath: userWalletDirectoryUrl.path) {
                    try fileManager.removeItem(at: userWalletDirectoryUrl)
                }
                return
            }

            try fileManager.createDirectory(at: userWalletDirectoryUrl, withIntermediateDirectories: true)

            let userWalletsWithoutSensitiveInformation: [UserWallet] = userWallets.map {
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
                let cardInfo = userWallet.cardInfo()
                let userWalletEncryptionKey = UserWalletEncryptionKeyFactory().encryptionKey(from: cardInfo)

                guard let encryptionKey = userWalletEncryptionKey else {
                    AppLog.shared.debug("User wallet \(userWallet.card.cardId) failed to generate encryption key")
                    continue
                }

                let sensitiveInformation = UserWallet.SensitiveInformation(wallets: userWallet.card.wallets)
                let sensitiveDataEncoded = try encrypt(encoder.encode(sensitiveInformation), with: encryptionKey.symmetricKey)
                let sensitiveDataPath = userWalletPath(for: userWallet)
                try sensitiveDataEncoded.write(to: sensitiveDataPath, options: .atomic)
                try excludeFromBackup(url: sensitiveDataPath)
            }
            AppLog.shared.debug("User wallets were saved successfully")
        } catch {
            AppLog.shared.debug("Failed to save user wallets")
            AppLog.shared.error(error)
        }
    }

    private func publicDataEncryptionKey() throws -> SymmetricKey {
        let secureStorage = SecureStorage()

        let encryptionKeyData = try secureStorage.get(publicDataEncryptionKeyStorageKey)
        if let encryptionKeyData = encryptionKeyData {
            let symmetricKey: SymmetricKey = .init(data: encryptionKeyData)
            return symmetricKey
        }

        let newEncryptionKey = SymmetricKey(size: .bits256)
        try secureStorage.store(newEncryptionKey.dataRepresentationWithHexConversion, forKey: publicDataEncryptionKeyStorageKey)
        return newEncryptionKey
    }

    private func userWalletListPath() -> URL {
        userWalletDirectoryUrl.appendingPathComponent("user_wallets.bin")
    }

    private func userWalletPath(for userWallet: UserWallet) -> URL {
        return userWalletDirectoryUrl.appendingPathComponent("user_wallet_\(userWallet.userWalletId.hexString.lowercased()).bin")
    }

    private func excludeFromBackup(url originalUrl: URL) throws {
        var url = originalUrl

        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try url.setResourceValues(resourceValues)
    }

    private func decrypt(_ data: Data, with key: SymmetricKey) throws -> Data {
        let sealedBox = try ChaChaPoly.SealedBox(combined: data)
        let decryptedData = try ChaChaPoly.open(sealedBox, using: key)
        return decryptedData
    }

    private func encrypt(_ data: Data, with key: SymmetricKey) throws -> Data {
        let sealedBox = try ChaChaPoly.seal(data, using: key)
        let sealedData = sealedBox.combined
        return sealedData
    }
}
