//
//  AppSettings.swift
//  Tangem
//
//  Created by Alexander Osokin on 03.11.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

class AppSettings {
    @AppStorageCompat(StorageType.twinCardOnboardingDisplayed)
    var isTwinCardOnboardingWasDisplayed: Bool = false

    @AppStorageCompat(StorageType.numberOfAppLaunches)
    var numberOfLaunches: Int = 0

    @AppStorageCompat(StorageType.didUserRespondToRateApp)
    var didUserRespondToRateApp: Bool = false

    @AppStorageCompat(StorageType.dismissRateAppAtLaunch)
    var dismissRateAppAtLaunch: Int? = nil

    @AppStorageCompat(StorageType.positiveBalanceAppearanceDate)
    var positiveBalanceAppearanceDate: Date? = nil

    @AppStorageCompat(StorageType.positiveBalanceAppearanceLaunch)
    var positiveBalanceAppearanceLaunch: Int? = nil

    @AppStorageCompat(StorageType.cardsStartedActivation)
    var cardsStartedActivation: [String] = []

    @AppStorageCompat(StorageType.didDisplayMainScreenStories)
    var didDisplayMainScreenStories: Bool = false

    // Temp migrated cards storage. Remove with LegacyCardMigrator
    @AppStorageCompat(StorageType.migratedCardsWithDefaultTokens)
    var migratedCardsWithDefaultTokens: [String] = []

    @AppStorageCompat(StorageType.validatedSignedHashesCards)
    var validatedSignedHashesCards: [String] = []

    @AppStorageCompat(StorageType.selectedCurrencyCode)
    var selectedCurrencyCode: String = "USD"

    @AppStorageCompat(StorageType.termsOfServiceAccepted)
    var termsOfServicesAccepted: [String] = []

    @AppStorageCompat(StorageType.askedToSaveUserWallets)
    var askedToSaveUserWallets: Bool = false

    @AppStorageCompat(StorageType.saveUserWallets)
    var saveUserWallets: Bool = false

    @AppStorageCompat(StorageType.selectedUserWalletId)
    var selectedUserWalletId: Data = .init()

    @AppStorageCompat(StorageType.saveAccessCodes)
    var saveAccessCodes: Bool = false

    @AppStorageCompat(StorageType.systemDeprecationWarningDismissDate)
    var systemDeprecationWarningDismissalDate: Date? = nil

    static let shared: AppSettings = .init()

    private init() {}

    deinit {
        AppLog.shared.debug("AppSettings deinit")
    }
}
