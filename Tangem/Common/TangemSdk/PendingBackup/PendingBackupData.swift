//
//  PendingBackupData.swift
//  Tangem
//
//  Created by Alexander Osokin on 18.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct PendingBackup: Codable {
    var cards: [String: PendingBackupCard]
}

struct PendingBackupCard: Codable {
    let hasWalletsError: Bool
    let hasBackupError: Bool
}
