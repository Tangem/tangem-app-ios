//
//  PendingBackupManager.swift
//  Tangem
//
//  Created by Alexander Osokin on 18.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class PendingBackupManager {
    private let pendingBackupRepository = PendingBackupRepository()

    /// We have to remember a current backup to handle interrupted backups
    @AppStorageCompat(StorageType.pendingBackupsCurrentID)
    private var currentBackupID: String? = nil

    func onProceedBackup(_ card: Card) {
        let cardInfo = CardInfo(card: CardDTO(card: card), walletData: .none, name: "")
        let backupValidator = BackupValidator()

        // clean card from existing pending backup
        if let existingBackupEntry = pendingBackupRepository.backups.first(where: { $0.value.cards.keys.contains(card.cardId) }) {
            var existingBackup = existingBackupEntry.value
            existingBackup.cards[card.cardId] = nil

            // If all cards from the old pending backup where processed, remove the old one
            pendingBackupRepository.backups[existingBackupEntry.key] = existingBackup.cards.isEmpty ? nil : existingBackup
        }

        let pendingBackupCard = PendingBackupCard(
            hasWalletsError: false,
            hasBackupError: !backupValidator.validate(backupStatus: cardInfo.card.backupStatus, wallets: cardInfo.card.wallets)
        )

        // Add card to the new backup
        if let currentBackupID {
            pendingBackupRepository.backups[currentBackupID]?.cards[card.cardId] = pendingBackupCard
        } else {
            // first card of the new backup
            let pendingBackup = PendingBackup(cards: [card.cardId: pendingBackupCard])
            let id = UUID().uuidString
            pendingBackupRepository.backups[id] = pendingBackup
            currentBackupID = id
        }

        pendingBackupRepository.save()
    }

    func onBackupCompleted() {
        guard let currentBackupID,
              let currentBackup = pendingBackupRepository.backups[currentBackupID] else {
            return
        }

        self.currentBackupID = nil

        for card in currentBackup.cards.values {
            if card.hasBackupError || card.hasWalletsError {
                return
            }
        }

        pendingBackupRepository.backups[currentBackupID] = nil
        pendingBackupRepository.save()
    }

    func fetchPendingCard(_ cardId: String) -> PendingBackupCard? {
        for backup in pendingBackupRepository.backups.values {
            if let card = backup.cards[cardId] {
                return card
            }
        }

        return nil
    }
}

// MARK: - CardID

private typealias CardID = String

// MARK: - PendingBackupRepository

private class PendingBackupRepository {
    var backups: [CardID: PendingBackup] = [:]

    @AppStorageCompat(StorageType.pendingBackups)
    private var pendingBackupData = Data()

    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    init() {
        fetch()
    }

    func save() {
        guard !backups.isEmpty else {
            pendingBackupData = Data()
            return
        }

        guard let data = try? PendingBackupRepository.encoder.encode(backups) else {
            return
        }

        pendingBackupData = data
    }

    private func fetch() {
        let backups = try? PendingBackupRepository.decoder.decode([String: PendingBackup].self, from: pendingBackupData)
        self.backups = backups ?? [:]
    }
}
