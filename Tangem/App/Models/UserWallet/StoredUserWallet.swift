//
//  StoredUserWallet.swift
//  Tangem
//
//  Created by Andrey Chukavin on 04.08.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import TangemSdk

struct StoredUserWallet: Identifiable, Encodable {
    var id = UUID()
    let userWalletId: Data
    var name: String
    var card: CardDTO
    var associatedCardIds: Set<String>
    let walletData: DefaultWalletData
    let artwork: ArtworkInfo?
}

extension StoredUserWallet {
    struct SensitiveInformation: Codable {
        let wallets: [CardDTO.Wallet]
    }
}

extension StoredUserWallet {
    var isLocked: Bool {
        card.wallets.isEmpty
    }

    func cardInfo() -> CardInfo {
        let cardArtwork: CardArtwork
        if let artwork = artwork {
            cardArtwork = .artwork(artwork)
        } else {
            cardArtwork = .noArtwork
        }

        return CardInfo(
            card: card,
            walletData: walletData,
            name: name,
            artwork: cardArtwork,
            primaryCard: nil
        )
    }
}

extension StoredUserWallet: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userWalletId = try container.decode(Data.self, forKey: .userWalletId)
        name = try container.decode(String.self, forKey: .name)
        associatedCardIds = try container.decode(Set<String>.self, forKey: .associatedCardIds)
        walletData = try container.decode(DefaultWalletData.self, forKey: .walletData)
        artwork = try container.decodeIfPresent(ArtworkInfo.self, forKey: .artwork)

        if let cardDTOv4 = try? container.decode(CardDTOv4.self, forKey: .card) {
            card = .init(cardDTOv4: cardDTOv4)
        } else {
            card = try container.decode(CardDTO.self, forKey: .card)
        }
    }
}

protocol NameableWallet {
    var name: String { get set }
}

extension StoredUserWallet: NameableWallet {}
