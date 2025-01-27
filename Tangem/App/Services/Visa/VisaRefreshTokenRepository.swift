//
//  VisaRefreshTokenRepository.swift
//  Tangem
//
//  Created by Andrew Son on 24/01/25.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import LocalAuthentication
import TangemSdk
import TangemVisa

protocol VisaRefreshTokenRepository: VisaRefreshTokenSaver {
    func save(refreshToken: String, cardId: String) throws
    func deleteToken(cardId: String) throws
    func clear()
    func fetch(using context: LAContext)
    func getToken(forCardId cardId: String) -> String?
    func lock()
}

extension VisaRefreshTokenRepository {
    func saveRefreshTokenToStorage(refreshToken: String, cardId: String) throws {
        try save(refreshToken: refreshToken, cardId: cardId)
    }
}

private struct VisaRefreshTokenRepositoryKey: InjectionKey {
    static var currentValue: VisaRefreshTokenRepository = CommonVisaRefreshTokenRepository()
}

extension InjectedValues {
    var visaRefreshTokenRepository: VisaRefreshTokenRepository {
        get { Self[VisaRefreshTokenRepositoryKey.self] }
        set { Self[VisaRefreshTokenRepositoryKey.self] = newValue }
    }
}

class CommonVisaRefreshTokenRepository: VisaRefreshTokenRepository {
    private(set) var tokens: [String: String] = [:]

    private let secureStorage = SecureStorage()
    private let biometricsStorage = BiometricsStorage()

    func save(refreshToken: String, cardId: String) throws {
        if tokens[cardId] == refreshToken {
            return
        }

        tokens[cardId] = refreshToken
        guard BiometricsUtil.isAvailable, AppSettings.shared.saveUserWallets else {
            return
        }

        let key = makeRefreshTokenStorageKey(cardId: cardId)
        var savedCardIds = loadStoredCardIds()
        if savedCardIds.contains(cardId) {
            try biometricsStorage.delete(key)
        }

        guard let tokenData = refreshToken.data(using: .utf8) else {
            return
        }

        try biometricsStorage.store(tokenData, forKey: key)
        savedCardIds.insert(cardId)

        storeCardsIds(savedCardIds)
    }

    func deleteToken(cardId: String) throws {
        tokens.removeValue(forKey: cardId)

        guard BiometricsUtil.isAvailable else {
            return
        }

        var savedCardIds = loadStoredCardIds()
        guard savedCardIds.contains(cardId) else {
            return
        }
        savedCardIds.remove(cardId)

        let storageKey = makeRefreshTokenStorageKey(cardId: cardId)
        try biometricsStorage.delete(storageKey)

        storeCardsIds(savedCardIds)
    }

    func clear() {
        do {
            let savedCardIds = loadStoredCardIds()
            tokens.removeAll()
            storeCardsIds([])
            for cardId in savedCardIds {
                let storageKey = makeRefreshTokenStorageKey(cardId: cardId)
                try biometricsStorage.delete(storageKey)
            }
        } catch {
            log("Failed to clear repository. Error: \(error)")
        }
    }

    func fetch(using context: LAContext) {
        do {
            var loadedTokens = [String: String]()
            for cardId in loadStoredCardIds() {
                let key = makeRefreshTokenStorageKey(cardId: cardId)
                guard let refreshTokenData = try biometricsStorage.get(key, context: context) else {
                    continue
                }

                loadedTokens[cardId] = String(data: refreshTokenData, encoding: .utf8)
            }

            tokens = loadedTokens
            storeCardsIds(Set(loadedTokens.keys))
        } catch {
            log("Failted to fetch token from storage. Error: \(error)")
        }
    }

    func lock() {
        tokens.removeAll()
        log("Repository locked")
    }

    func getToken(forCardId cardId: String) -> String? {
        return tokens[cardId]
    }

    private func makeRefreshTokenStorageKey(cardId: String) -> String {
        return "\(StorageKey.visaRefreshToken.rawValue)_\(cardId)"
    }

    private func log<T>(_ message: @autoclosure () -> T) {
        AppLog.shared.debug("[VisaRefreshTokenRepository] - \(message())")
    }

    private func loadStoredCardIds() -> Set<String> {
        do {
            guard let data = try secureStorage.get(StorageKey.visaCardIds.rawValue) else {
                return []
            }

            let cards = try JSONDecoder().decode(Set<String>.self, from: data)
            return cards
        } catch {
            log("Failed to load and decode stored card ids. Error: \(error)")
            return []
        }
    }

    private func storeCardsIds(_ cardIds: Set<String>) {
        do {
            let data = try JSONEncoder().encode(cardIds)
            try secureStorage.store(data, forKey: StorageKey.visaCardIds.rawValue)
        } catch {
            log("Failed to encode and store card ids. Error: \(error)")
        }
    }
}

extension CommonVisaRefreshTokenRepository {
    enum StorageKey: String {
        case visaCardIds
        case visaRefreshToken
    }
}
