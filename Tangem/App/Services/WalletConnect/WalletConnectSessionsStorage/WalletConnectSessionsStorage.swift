//
//  WalletConnectSessionsStorage.swift
//  Tangem
//
//  Created by Andrew Son on 27/12/22.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine

protocol WalletConnectSessionsStorage: Actor, Initializable {
    var sessions: AsyncStream<[WalletConnectSavedSession]> { get async }

    func loadSessions()
    func save(_ session: WalletConnectSavedSession)
    func session(with id: Int) -> WalletConnectSavedSession?
    func session(with topic: String) -> WalletConnectSavedSession?
    func remove(_ session: WalletConnectSavedSession)
    func removeSessions(for userWalletId: String) -> [WalletConnectSavedSession]
}

private struct WalletConnectSessionsStorageKey: InjectionKey {
    static var currentValue: WalletConnectSessionsStorage = CommonWalletConnectSessionsStorage()
}

extension InjectedValues {
    var walletConnectSessionsStorage: WalletConnectSessionsStorage {
        get { Self[WalletConnectSessionsStorageKey.self] }
        set { Self[WalletConnectSessionsStorageKey.self] = newValue }
    }

    var walletConnectSessionsStorageInitializable: Initializable { Self[WalletConnectSessionsStorageKey.self] }
}

actor CommonWalletConnectSessionsStorage {
    @Injected(\.persistentStorage) private var storage: PersistentStorageProtocol
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    var sessions: AsyncStream<[WalletConnectSavedSession]> {
        get async {
            await allSessions.values
        }
    }

    private let allSessions: CurrentValueSubject<[WalletConnectSavedSession], Never> = .init([])
    private var sessionsFilteringSubscription: AnyCancellable?

    func loadSessions() {
        var savedSessions: [WalletConnectSavedSession] = (try? storage.value(for: .allWalletConnectSessions)) ?? []
        allSessions.value = savedSessions
    }

    private func saveCachedSessions() {
        saveSessionsToFile(allSessions.value)
    }

    private func saveSessionsToFile(_ sessions: [WalletConnectSavedSession]) {
        do {
            try storage.store(value: sessions, for: .allWalletConnectSessions)
        } catch {
            AppLog.shared.error(error)
        }
    }
}

extension CommonWalletConnectSessionsStorage: WalletConnectSessionsStorage {
    func save(_ session: WalletConnectSavedSession) {
        allSessions.value.append(session)
        saveCachedSessions()
    }

    func session(with id: Int) -> WalletConnectSavedSession? {
        return allSessions.value.first(where: { $0.id == id })
    }

    func session(with topic: String) -> WalletConnectSavedSession? {
        return allSessions.value.first(where: { $0.topic == topic })
    }

    func remove(_ session: WalletConnectSavedSession) {
        allSessions.value.remove(session)
        saveCachedSessions()
    }

    func removeSessions(for userWalletId: String) -> [WalletConnectSavedSession] {
        var sessions = allSessions.value
        var removedSessions = [WalletConnectSavedSession]()
        var indexiesToRemove = [Int]()
        for i in stride(from: sessions.endIndex - 1, through: 0, by: -1) {
            let session = sessions[i]
            if session.userWalletId.caseInsensitiveCompare(userWalletId) == .orderedSame {
                indexiesToRemove.append(i)
                removedSessions.append(session)
            }
        }

        indexiesToRemove.forEach {
            sessions.remove(at: $0)
        }

        if removedSessions.isEmpty {
            return []
        }

        saveSessionsToFile(sessions)
        allSessions.value = sessions
        return removedSessions
    }
}

// Temp logic for migrating from old saved sessions file structure to a new one
extension CommonWalletConnectSessionsStorage: Initializable {
    nonisolated func initialize() {
        runTask { [weak self] in
            await self?.migrateSavedSessions()
        }
    }

    private func migrateSavedSessions() {
        var sessionsToSave = [WalletConnectSavedSession]()
        for userWallet in userWalletRepository.userWallets {
            if let oldSavedSessions: [WalletConnectSavedSession] = try? storage.value(for: .walletConnectSessions(userWalletId: userWallet.userWalletId.hexString)) {
                sessionsToSave.append(contentsOf: oldSavedSessions)
                try? storage.store(value: [WalletConnectSavedSession]?(nil), for: .walletConnectSessions(userWalletId: userWallet.userWalletId.hexString))
            }
        }

        if sessionsToSave.isEmpty { return }

        saveSessionsToFile(sessionsToSave)
    }
}
