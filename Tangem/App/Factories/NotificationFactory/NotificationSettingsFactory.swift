//
//  NotificationSettingsFactory.swift
//  Tangem
//
//  Created by Andrew Son on 14/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct NotificationSettingsFactory {
    func buildMissingDerivationNotificationSettings(for numberOfNetworks: Int) -> NotificationView.Settings {
        .init(
            colorScheme: .white,
            icon: .init(image: Assets.blueCircleWarning.image),
            title: Localization.mainWarningMissingDerivationTitle,
            description: Localization.mainWarningMissingDerivationDescription(numberOfNetworks),
            isDismissable: false,
            dismissAction: nil
        )
    }

    func lockedWalletNotificationSettings() -> NotificationView.Settings {
        .init(
            colorScheme: .gray,
            icon: .init(image: Assets.lock.image, color: Colors.Icon.primary1),
            title: Localization.commonUnlockNeeded,
            description: Localization.unlockWalletDescriptionShort(BiometricAuthorizationUtils.biometryType.name),
            isDismissable: false,
            dismissAction: nil
        )
    }

    func missingBackupNotificationSettings() -> NotificationView.Settings {
        .init(
            colorScheme: .white,
            icon: .init(image: Assets.attention.image),
            title: Localization.mainNoBackupWarningTitle,
            description: Localization.mainNoBackupWarningSubtitle,
            isDismissable: false,
            dismissAction: nil
        )
    }
}
