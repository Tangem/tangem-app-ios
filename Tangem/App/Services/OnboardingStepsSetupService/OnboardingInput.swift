//
//  OnboardingInput.swift
//  Tangem
//
//  Created by Andrew Son on 15.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import UIKit
import TangemSdk

struct OnboardingInput { // TODO: Split to coordinator options and input
    let tangemSdk: TangemSdk
    let backupService: BackupService
    let steps: OnboardingSteps
    let cardInput: CardInput
    let twinData: TwinData?
    var isStandalone = false
    var userWalletToDelete: UserWallet? // for twins. TODO: refactor UserWalletRepository to remove this
}

extension OnboardingInput {
    enum CardInput {
        case cardModel(_ cardModel: CardViewModel)
        case cardId(_ cardId: String)

        var cardModel: CardViewModel? {
            switch self {
            case .cardModel(let cardModel):
                return cardModel
            default:
                return nil
            }
        }

        var cardId: String {
            switch self {
            case .cardModel(let cardModel):
                return cardModel.cardId
            case .cardId(let cardId):
                return cardId
            }
        }
    }
}
