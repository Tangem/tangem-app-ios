//
//  WarningEventsFactory.swift
//  Tangem
//
//  Created by Alexander Osokin on 11.08.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct WarningEventsFactory {
    func makeWarningEvents(for card: Card) -> [WarningEvent] {
        var warnings: [WarningEvent] = []

        if card.firmwareVersion.type != .sdk &&
            card.attestation.status == .failed {
            warnings.append(.failedToValidateCard)
        }

        if AppEnvironment.current.isTestnet {
            warnings.append(.testnetCard)
        } else if card.firmwareVersion.type == .sdk && !DemoUtil().isDemoCard(cardId: card.cardId) {
            warnings.append(.devCard)
        }

        for wallet in card.wallets {
            if let remainingSignatures = wallet.remainingSignatures,
               remainingSignatures <= 10 {
                warnings.append(.lowSignatures(count: remainingSignatures))
                break
            }
        }

        return warnings
    }
}
