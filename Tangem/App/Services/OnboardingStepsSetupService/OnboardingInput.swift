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
    let primaryCardId: String
    let cardInitializer: CardInitializable?
    let steps: OnboardingSteps
    let cardInput: CardInput
    let twinData: TwinData?
    var isStandalone = false
    var userWalletToDelete: UserWalletId? // for twins. TODO: refactor UserWalletRepository to remove this
}

extension OnboardingInput {
    enum CardInput {
        case cardInfo(_ cardInfo: CardInfo)
        case userWalletModel(_ userWalletModel: UserWalletModel)
        case cardId(_ cardId: String)

        var emailData: [EmailCollectedData] {
            switch self {
            case .cardInfo(let cardInfo):
                let factory = UserWalletConfigFactory(cardInfo)
                return factory.makeConfig().emailData
            case .userWalletModel(let userWalletModel):
                return userWalletModel.emailData
            case .cardId:
                return []
            }
        }

        var demoBackupDisabledLocalizedReason: String? {
            switch self {
            case .cardInfo(let cardInfo):
                let factory = UserWalletConfigFactory(cardInfo)
                return factory.makeConfig().getFeatureAvailability(.backup).disabledLocalizedReason
            case .userWalletModel(let userWalletModel):
                return userWalletModel.config.getDisabledLocalizedReason(for: .backup)
            case .cardId:
                return nil
            }
        }

        var disclaimer: TOU? {
            switch self {
            case .cardInfo(let cardInfo):
                let factory = UserWalletConfigFactory(cardInfo)
                return factory.makeConfig().tou
            case .userWalletModel(let userWalletModel):
                return userWalletModel.config.tou
            case .cardId:
                return nil
            }
        }

        var userWalletModel: UserWalletModel? {
            switch self {
            case .userWalletModel(let userWalletModel):
                return userWalletModel
            default:
                return nil
            }
        }

        var config: UserWalletConfig? {
            switch self {
            case .cardInfo(let cardInfo):
                let factory = UserWalletConfigFactory(cardInfo)
                return factory.makeConfig()
            case .userWalletModel(let userWalletModel):
                return userWalletModel.config
            case .cardId:
                return nil
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
            case .userWalletModel(let userWalletModel):
                return .init(
                    supportsOnlineImage: userWalletModel.config.hasFeature(.onlineImage),
                    cardId: userWalletModel.tangemApiAuthData.cardId,
                    cardPublicKey: userWalletModel.tangemApiAuthData.cardPublicKey
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
