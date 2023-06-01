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
    let backupService: BackupService
    let cardInitializer: CardInitializable?
    let steps: OnboardingSteps
    let cardInput: CardInput
    let twinData: TwinData?
    var isStandalone = false
    var userWalletToDelete: UserWallet? // for twins. TODO: refactor UserWalletRepository to remove this
}

extension OnboardingInput {
    enum CardInput {
        case cardInfo(_ cardInfo: CardInfo)
        case cardModel(_ cardModel: CardViewModel)
        case cardId(_ cardId: String)

        var emailData: [EmailCollectedData] {
            switch self {
            case .cardInfo(let cardInfo):
                let factory = UserWalletConfigFactory(cardInfo)
                return factory.makeConfig().emailData
            case .cardModel(let cardModel):
                return cardModel.emailData
            case .cardId:
                return []
            }
        }

        var demoBackupDisabledLocalizedReason: String? {
            switch self {
            case .cardInfo(let cardInfo):
                let factory = UserWalletConfigFactory(cardInfo)
                return factory.makeConfig().getFeatureAvailability(.backup).disabledLocalizedReason
            case .cardModel(let cardModel):
                return cardModel.getDisabledLocalizedReason(for: .backup)
            case .cardId:
                return nil
            }
        }

        var disclaimer: TOU? {
            switch self {
            case .cardInfo(let cardInfo):
                let factory = UserWalletConfigFactory(cardInfo)
                return factory.makeConfig().tou
            case .cardModel(let cardModel):
                return cardModel.cardDisclaimer
            case .cardId:
                return nil
            }
        }

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
            case .cardInfo(let cardInfo):
                return cardInfo.card.cardId
            case .cardModel(let cardModel):
                return cardModel.cardId
            case .cardId(let cardId):
                return cardId
            }
        }

        var imageLoadInput: ImageLoadInput {
            switch self {
            case .cardInfo(let cardInfo):
                let config = UserWalletConfigFactory(cardInfo).makeConfig()
                return .init(
                    supportsOnlineImage: config.hasFeature(.onlineImage),
                    cardId: cardInfo.card.cardId,
                    cardPublicKey: cardInfo.card.cardPublicKey
                )
            case .cardModel(let cardModel):
                return .init(
                    supportsOnlineImage: cardModel.supportsOnlineImage,
                    cardId: cardModel.cardId,
                    cardPublicKey: cardModel.cardPublicKey
                )
            case .cardId(let cardId):
                return .init(
                    supportsOnlineImage: true,
                    cardId: cardId,
                    cardPublicKey: Data()
                ) // we assume that cache exists
            }
        }
    }

    // TODO: Refactor CardImageProvider initialization/loading and pass it as a dependency. CardId and cardPublicKey should be private
    struct ImageLoadInput {
        let supportsOnlineImage: Bool
        let cardId: String
        let cardPublicKey: Data
    }
}
