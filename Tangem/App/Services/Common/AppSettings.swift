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

    @AppStorageCompat(StorageType.cardsStartedActivation)
    var cardsStartedActivation: [String] = []

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

    @AppStorageCompat(StorageType.understandsAddressNetworkRequirements)
    var understandsAddressNetworkRequirements: [String] = []

    @AppStorageCompat(StorageType.promotionQuestionnaireFinished)
    var promotionQuestionnaireFinished: Bool = false

    @AppStorageCompat(StorageType.hideSensitiveInformation)
    var isHidingSensitiveInformation: Bool = false

    @AppStorageCompat(StorageType.hideSensitiveAvailable)
    var isHidingSensitiveAvailable: Bool = false

    @AppStorageCompat(StorageType.shouldHidingSensitiveInformationSheetShowing)
    var shouldHidingSensitiveInformationSheetShowing: Bool = true

    @AppStorageCompat(StorageType.appTheme, store: .standard)
    var appTheme: ThemeOption = .system

    @AppStorageCompat(StorageType.userDidSwipeWalletsOnMainScreen)
    var userDidSwipeWalletsOnMainScreen: Bool = false

    @AppStorageCompat(StorageType.mainPromotionDismissed)
    var mainPromotionDismissed: [String] = []

    @AppStorageCompat(StorageType.tokenPromotionDismissed)
    var tokenPromotionDismissed: [String] = []

    @AppStorageCompat(StorageType.userDidTapSendScreenSummary)
    var userDidTapSendScreenSummary: Bool = false

    @AppStorageCompat(StorageType.forcedDemoCardId)
    var forcedDemoCardId: String? = nil

    @AppStorageCompat(StorageType.didMigrateUserWalletNames)
    var didMigrateUserWalletNames: Bool = false

    @AppStorageCompat(StorageType.userWalletIdsWithRing)
    var userWalletIdsWithRing: [String] = []

    static let shared: AppSettings = .init()

    private init() {}

    deinit {
        AppLog.debug(self)
    }
}
