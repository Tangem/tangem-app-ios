//
//  WarningEvent+.swift
//  Tangem
//
//  Created by Andrew Son on 28/12/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

extension WarningEvent {
    var warning: AppWarning {
        switch self {
        case .numberOfSignedHashesIncorrect:
            return WarningsList.numberOfSignedHashesIncorrect
        case .rateApp:
            return WarningsList.rateApp
        case .failedToValidateCard:
            return WarningsList.failedToVerifyCard
        case .multiWalletSignedHashes:
            return WarningsList.multiWalletSignedHashes
        case .testnetCard:
            return WarningsList.testnetCard
        case .lowSignatures(let count):
            return WarningsList.lowSignatures(count: count)
        case .demoCard:
            return WarningsList.demoCard
        case .devCard:
            return WarningsList.devCard
        case .oldCard:
            return WarningsList.oldCard
        case .oldDeviceOldCard:
            return WarningsList.oldDeviceOldCard
        case .legacyDerivation:
            return WarningsList.legacyDerivation
        case .systemDeprecationTemporary:
            return WarningsList.systemDeprecationTemporary
        case .systemDeprecationPermanent(let dateString):
            return WarningsList.systemDeprecationPermanent(dateString: dateString)
        }
    }
}

private enum WarningsList {
    static let warningTitle = Localization.commonWarning

    static let oldCard = AppWarning(title: warningTitle, message: Localization.alertOldCard, priority: .info, type: .permanent)
    static let oldDeviceOldCard = AppWarning(title: warningTitle, message: Localization.alertOldDeviceThisCard, priority: .info, type: .permanent)
    static let devCard = AppWarning(title: warningTitle, message: Localization.alertDeveloperCard, priority: .critical, type: .permanent)
    static let numberOfSignedHashesIncorrect = AppWarning(title: warningTitle, message: Localization.alertCardSignedTransactions, priority: .info, type: .temporary, event: .numberOfSignedHashesIncorrect)
    static let rateApp = AppWarning(title: Localization.warningRateAppTitle, message: Localization.warningRateAppMessage, priority: .info, type: .temporary, event: .rateApp)
    static let failedToVerifyCard = AppWarning(title: Localization.warningFailedToVerifyCardTitle, message: Localization.warningFailedToVerifyCardMessage, priority: .critical, type: .permanent, event: .failedToValidateCard)
    static let multiWalletSignedHashes = AppWarning(title: Localization.warningImportantSecurityInfo("\u{26A0}"), message: Localization.warningSignedTxPreviously, priority: .info, type: .temporary, location: [.main], event: .multiWalletSignedHashes)
    static let testnetCard = AppWarning(title: warningTitle, message: Localization.warningTestnetCardMessage, priority: .critical, type: .permanent, location: [.main, .send], event: .testnetCard)
    static let demoCard = AppWarning(title: warningTitle, message: Localization.alertDemoMessage, priority: .critical, type: .permanent, location: [.main, .send], event: .demoCard)
    static let legacyDerivation = AppWarning(title: warningTitle, message: Localization.alertManageTokensAddressesMessage, priority: .critical, type: .permanent, location: [.manageTokens], event: .legacyDerivation)

    static func lowSignatures(count: Int) -> AppWarning {
        let message = Localization.warningLowSignaturesFormat("\(count)")
        return AppWarning(title: warningTitle, message: message, priority: .critical, type: .permanent)
    }

    static let systemDeprecationTemporary = AppWarning(
        title: Localization.warningSystemUpdateTitle,
        message: Localization.warningSystemUpdateMessage,
        priority: .warning,
        type: .temporary,
        event: .systemDeprecationTemporary
    )

    static func systemDeprecationPermanent(dateString: String) -> AppWarning {
        return AppWarning(
            title: Localization.warningSystemDeprecationTitle,
            // we need to search and replace double dot, because in ru locale year is clipped as `г.`. So at the end of the sentence
            // we have double dot... But if you are using Buddhist calendar, you will have `2023 г. ВЕ.`
            message: String(format: Localization.warningSystemDeprecationWithDateMessage(dateString))
                .replacingOccurrences(of: "..", with: "."),
            priority: .critical,
            type: .permanent
        )
    }
}
