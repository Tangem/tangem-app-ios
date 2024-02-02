//
//  StorageType.swift
//  Tangem
//
//  Created by Andrew Son on 11/10/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

enum StorageType: String {
    case oldDeviceOldCardAlert = "tangem_tap_oldDeviceOldCard_shown"
    case selectedCurrencyCode = "tangem_tap_selected_currency_code"
    case termsOfServiceAccepted = "tangem_tap_terms_of_service_accepted"
    case firstTimeScan = "tangem_tap_first_time_scan"
    case validatedSignedHashesCards = "tangem_tap_validated_signed_hashes_cards"
    case twinCardOnboardingDisplayed = "tangem_tap_twin_card_onboarding_displayed"
    case numberOfAppLaunches = "tangem_tap_number_of_launches"
    case readWarningHashes = "tangem_tap_read_warnings"
    case searchedCards = "tangem_tap_searched_cards" // for tokens search
    case isMigratedToNewUserDefaults = "tangem_tap_migrate_to_new_defaults"
    case cardsStartedActivation = "tangem_cards_started_activation"
    case cardsFinishedActivation = "tangem_cards_finished_activation"
    case termsOfServicesAccepted = "tangem_tap_terms_of_services_accepted"
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
    case tangemExpressMainPromotionDismissed = "tangem_express_main_promotion_dismissed"
    case tangemExpressTokenPromotionDismissed = "tangem_express_token_promotion_dismissed"
}
