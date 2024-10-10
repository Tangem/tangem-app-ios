//
//  CardInfo.swift
//  Tangem
//
//  Created by Alexander Osokin on 25.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdkLocal

struct CardInfo {
    var card: CardDTO
    var walletData: DefaultWalletData
    var name: String
    var artwork: CardArtwork = .notLoaded
    var primaryCard: PrimaryCard?

    var cardIdFormatted: String {
        if case .twin(_, let twinData) = walletData {
            return AppTwinCardIdFormatter.format(cid: card.cardId, cardNumber: twinData.series.number)
        } else {
            return AppCardIdFormatter(cid: card.cardId).formatted()
        }
    }
}
