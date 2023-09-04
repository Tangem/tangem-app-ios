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
            message: description,
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
        case .multiWalletSignedHashes:
            return [.learnMore]
        case .rateApp:
            return [.reportProblem, .rateApp]
        default:
            return []
        }
    }

    private var priority: WarningPriority {
        switch self {
        case .numberOfSignedHashesIncorrect, .multiWalletSignedHashes, .rateApp, .oldDeviceOldCard, .oldCard:
            return .info
        case .failedToValidateCard, .testnetCard, .demoCard, .devCard, .lowSignatures, .legacyDerivation, .systemDeprecationPermanent:
            return .critical
        case .systemDeprecationTemporary:
            return .warning
        }
    }

    private var type: WarningType {
        switch self {
        case .numberOfSignedHashesIncorrect, .multiWalletSignedHashes, .rateApp, .systemDeprecationTemporary:
            return .temporary
        case .failedToValidateCard, .testnetCard, .demoCard, .oldDeviceOldCard, .oldCard, .devCard, .lowSignatures, .legacyDerivation, .systemDeprecationPermanent:
            return .permanent
        }
    }

    @available(*, deprecated, message: "We need to have different titles for notification and for AppWarning. Will be removed after new design release")
    private var appWarningTitle: String {
        switch self {
        case .multiWalletSignedHashes:
            return Localization.warningImportantSecurityInfo("\u{26A0}")
        case .rateApp:
            return Localization.warningRateAppTitle
        case .failedToValidateCard:
            return Localization.warningFailedToVerifyCardTitle
        case .systemDeprecationTemporary:
            return Localization.warningSystemUpdateTitle
        case .systemDeprecationPermanent:
            return Localization.warningSystemDeprecationTitle
        case .testnetCard, .demoCard, .oldDeviceOldCard, .oldCard, .devCard, .lowSignatures, .numberOfSignedHashesIncorrect, .legacyDerivation:
            return defaultTitle
        }
    }
}
