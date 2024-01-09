//
//  WarningEvent+.swift
//  Tangem
//
//  Created by Andrew Son on 28/12/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available(*, deprecated, message: "Use NotificationView instead of AppWarning")
extension WarningEvent {
    var warning: AppWarning {
        AppWarning(
            title: appWarningTitle,
            message: description ?? "",
            priority: priority,
            type: type,
            location: Array(locationsToDisplay),
            event: self
        )
    }

    var locationsToDisplay: Set<WarningsLocation> {
        switch self {
        case .legacyDerivation:
            return [.manageTokens]
        case .testnetCard, .oldDeviceOldCard, .demoCard:
            return [.main, .send]
        default:
            return [.main]
        }
    }

    var buttons: [WarningView.WarningButton] {
        switch self {
        case .numberOfSignedHashesIncorrect, .systemDeprecationTemporary:
            return [.okGotIt]
        case .rateApp:
            return [.reportProblem, .rateApp]
        default:
            return []
        }
    }

    private var priority: WarningPriority {
        switch self {
        case .numberOfSignedHashesIncorrect, .rateApp, .oldDeviceOldCard, .oldCard:
            return .info
        case .failedToVerifyCard, .testnetCard, .demoCard, .devCard, .lowSignatures, .legacyDerivation, .systemDeprecationPermanent:
            return .critical
        case .systemDeprecationTemporary, .supportedOnlySingleCurrencyWallet:
            return .warning
        case .missingDerivation, .walletLocked, .missingBackup, .tangemExpressPromotion: // New cases won't be displayed in new design
            return .info
        }
    }

    private var type: WarningType {
        switch self {
        case .numberOfSignedHashesIncorrect, .rateApp, .systemDeprecationTemporary, .supportedOnlySingleCurrencyWallet:
            return .temporary
        case .failedToVerifyCard, .testnetCard, .demoCard, .oldDeviceOldCard, .oldCard, .devCard, .lowSignatures, .legacyDerivation, .systemDeprecationPermanent:
            return .permanent
        case .missingDerivation, .walletLocked, .missingBackup, .tangemExpressPromotion: // New cases won't be displayed in new design
            return .temporary
        }
    }

    @available(*, deprecated, message: "We need to have different titles for notification and for AppWarning. Will be removed after new design release")
    private var appWarningTitle: String {
        switch self {
        case .rateApp:
            return Localization.warningRateAppTitle
        case .failedToVerifyCard:
            return Localization.warningFailedToVerifyCardTitle
        case .systemDeprecationTemporary:
            return Localization.warningSystemUpdateTitle
        case .systemDeprecationPermanent:
            return Localization.warningSystemDeprecationTitle
        case .testnetCard, .demoCard, .oldDeviceOldCard, .oldCard, .devCard, .lowSignatures, .numberOfSignedHashesIncorrect, .legacyDerivation:
            return defaultTitle
        case .missingDerivation, .walletLocked, .missingBackup, .supportedOnlySingleCurrencyWallet:
            // New cases won't be displayed in new design
            return defaultTitle
        case .tangemExpressPromotion:
            return Localization.mainSwapPromotionTitle
        }
    }
}
