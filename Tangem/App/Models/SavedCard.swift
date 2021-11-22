//
//  SavedCard.swift
//  Tangem
//
//  Created by Andrew Son on 28/06/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct SavedCard: Codable {
    let cardId: String
    let wallets: [SavedCardWallet]
    
    static func savedCard(from card: Card) -> SavedCard {
        let wallets: [SavedCardWallet] = card.wallets.map {
            .init(publicKey: $0.publicKey, curve: $0.curve, chainCode: $0.chainCode)
        }
        
        return .init(cardId: card.cardId, wallets: wallets)
    }
}

struct SavedCardWallet: Codable {
    let publicKey: Data
    let curve: EllipticCurve
    let chainCode: Data?
}
