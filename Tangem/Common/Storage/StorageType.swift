//
//  StorageType.swift
//  Tangem
//
//  Created by Andrew Son on 11/10/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

enum StorageType: String {
    case selectedCurrencyCode = "tangem_tap_selected_currency_code"
    case termsOfServiceAccepted = "tangem_tap_terms_of_service_accepted"
    case validatedSignedHashesCards = "tangem_tap_validated_signed_hashes_cards"
    case twinCardOnboardingDisplayed = "tangem_tap_twin_card_onboarding_displayed"
    case numberOfAppLaunches = "tangem_tap_number_of_launches"
    case cardsStartedActivation = "tangem_cards_started_activation"
    case askedToSaveUserWallets = "tangem_asked_to_save_user_wallets"
    case saveUserWallets = "tangem_save_user_wallets"
    case selectedUserWalletId = "tangem_selected_user_wallet_id"
    case saveAccessCodes = "tangem_save_access_codes"
    case systemDeprecationWarningDismissDate = "tangem_system_deprecation_warning_dismiss_date"
    case understandsAddressNetworkRequirements = "tangem_understands_address_network_requirements"
    case promotionQuestionnaireFinished = "promotion_questionnaire_finished"
    case hideSensitiveInformation = "hide_sensitive_information"
    case hideSensitiveAvailable = "hide_sensitive_available"
    case shouldHidingSensitiveInformationSheetShowing = "should_hiding_sensitive_information_sheet_showing"
    case appTheme = "app_theme"
    case userDidSwipeWalletsOnMainScreen = "user_did_swipe_wallets_on_main_screen"
    case mainPromotionDismissed = "main_promotion_dismissed"
    case tokenPromotionDismissed = "token_promotion_dismissed"
    case userDidTapSendScreenSummary = "user_did_tap_send_screen_summary"
    case pendingBackups = "pending_backups"
    case pendingBackupsCurrentID = "pending_backups_current_id"
    case forcedDemoCardId = "forced_demo_card_id"
    case didMigrateUserWalletNames = "did_migrate_user_wallet_names_again"
    case userWalletIdsWithRing = "tangem_userwalletIds_with_ring"
}
