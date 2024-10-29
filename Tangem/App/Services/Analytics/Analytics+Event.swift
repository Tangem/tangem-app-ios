//
//  AnalyticsEvent.swift
//  Tangem
//
//  Created by Andrew Son on 24/10/22.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

extension Analytics {
    enum Event: String {
        case signedIn = "[Basic] Signed in"
        case toppedUp = "[Basic] Topped up"
        case balanceLoaded = "[Basic] Balance Loaded"
        case tokenBalanceLoaded = "[Basic] Token Balance"
        case cardWasScanned = "[Basic] Card Was Scanned"
        case transactionSent = "[Basic] Transaction sent"
        case requestSupport = "[Basic] Request Support"
        case buttonTokensList = "[Introduction Process] Button - Tokens List"
        case buttonBuyCards = "[Introduction Process] Button - Buy Cards"
        case introductionProcessButtonScanCard = "[Introduction Process] Button - Scan Card"
        case introductionProcessOpened = "[Introduction Process] Introduction Process Screen Opened"
        case introductionProcessLearn = "[Introduction Process] Button - Learn"
        case promoBuy = "[Promo Screen] Button - Buy"
        case promoSuccessOpened = "[Promo Screen] Success Screen Opened"
        case shopScreenOpened = "[Shop] Shop Screen Opened"
        case purchased = "[Shop] Purchased"
        case redirected = "[Shop] Redirected"
        case signInScreenOpened = "[Sign In] Sing In Screen Opened"
        case buttonBiometricSignIn = "[Sign In] Button - Biometric Sign In"
        case buttonCardSignIn = "[Sign In] Button - Card Sign In"
        case onboardingStarted = "[Onboarding] Onboarding Started"
        case onboardingFinished = "[Onboarding] Onboarding Finished"
        case createWalletScreenOpened = "[Onboarding / Create Wallet] Create Wallet Screen Opened"
        case buttonCreateWallet = "[Onboarding / Create Wallet] Button - Create Wallet"
        case walletCreatedSuccessfully = "[Onboarding / Create Wallet] Wallet Created Successfully"
        case backupScreenOpened = "[Onboarding / Backup] Backup Screen Opened"
        case backupStarted = "[Onboarding / Backup] Backup Started"
        case backupSkipped = "[Onboarding / Backup] Backup Skipped"
        case settingAccessCodeStarted = "[Onboarding / Backup] Setting Access Code Started"
        case accessCodeEntered = "[Onboarding / Backup] Access Code Entered"
        case accessCodeReEntered = "[Onboarding / Backup] Access Code Re-entered"
        case backupFinished = "[Onboarding / Backup] Backup Finished"
        case backupResetCardNotification = "[Onboarding / Backup] Reset Card Notification"
        case activationScreenOpened = "[Onboarding / Top Up] Activation Screen Opened"
        case buttonBuyCrypto = "[Onboarding / Top Up] Button - Buy Crypto"
        case onboardingButtonShowTheWalletAddress = "[Onboarding / Top Up] Button - Show the Wallet Address"
        case onboardingEnableBiometric = "[Onboarding / Biometric] Enable Biometric"
        case allowBiometricID = "[Onboarding / Biometric] Allow Face ID / Touch ID (System)"
        case twinningScreenOpened = "[Onboarding / Twins] Twinning Screen Opened"
        case twinSetupStarted = "[Onboarding / Twins] Twin Setup Started"
        case twinSetupFinished = "[Onboarding / Twins] Twin Setup Finished"
        case onboardingButtonChat = "[Onboarding] Button - Chat"
        case mainScreenOpened = "[Main Screen] Screen opened"
        case noticeRateTheAppButtonTapped = "[Main Screen] Notice - Rate The App Button Tapped"
        case buttonManageTokens = "[Portfolio] Button - Manage Tokens"

        case organizeTokensScreenOpened = "[Portfolio / Organize Tokens] Organize Tokens Screen Opened"
        case organizeTokensButtonSortByBalance = "[Portfolio / Organize Tokens] Button - By Balance"
        case organizeTokensButtonGroup = "[Portfolio / Organize Tokens] Button - Group"
        case organizeTokensButtonApply = "[Portfolio / Organize Tokens] Button - Apply"
        case organizeTokensButtonCancel = "[Portfolio / Organize Tokens] Button - Cancel"
        case detailsScreenOpened = "[Details Screen] Details Screen Opened"
        case buttonRemoveToken = "[Token] Button - Remove Token"
        case buttonExplore = "[Token] Button - Explore"
        case buttonReload = "[Token] Button - Reload"
        case buttonBuy = "[Token] Button - Buy"
        case buttonSell = "[Token] Button - Sell"
        case buttonExchange = "[Token] Button - Exchange"
        case buttonSend = "[Token] Button - Send"
        case buttonReceive = "[Token] Button - Receive"
        case buttonUnderstand = "[Token] Button - Understand"
        case tokenBought = "[Token] Token Bought"
        case receiveScreenOpened = "[Token / Receive] Receive Screen Opened"
        case buttonCopyAddress = "[Token / Receive] Button - Copy Address"
        case buttonShareAddress = "[Token / Receive] Button - Share Address"
        case buttonAddTokenTrustline = "[Token] Button - Token Trustline"
        case stakingClicked = "[Token] Staking Clicked"

        // MARK: - Send

        case buttonPaste = "[Token / Send] Button - Paste"
        case buttonSwapCurrency = "[Token / Send] Button - Swap Currency"
        case sendScreenOpened = "[Token / Send] Send Screen Opened"
        case sendAddressEntered = "[Token / Send] Address Entered"
        case sendButtonQRCode = "[Token / Send] Button - QR Code"
        case sendAddressScreenOpened = "[Token / Send] Address Screen Opened"
        case sendAmountScreenOpened = "[Token / Send] Amount Screen Opened"
        case sendMaxAmountTapped = "[Token / Send] Max Amount Taped"
        case sendSelectedCurrency = "[Token / Send] Selected Currency"
        case sendFeeScreenOpened = "[Token / Send] Fee Screen Opened"
        case sendFeeSelected = "[Token / Send] Fee Selected"
        case sendCustomFeeClicked = "[Token / Send] Custom Fee Clicked"
        case sendGasPriceInserted = "[Token / Send] Gas Price Inserted"
        case sendCustomFeeInserted = "[Token / Send] Custom Fee Inserted"
        case sendGasLimitInserted = "[Token / Send] Gas Limit Inserted"
        case sendMaxFeeInserted = "[Token / Send] Max Fee Inserted"
        case sendPriorityFeeInserted = "[Token / Send] Priority Fee Inserted"
        case sendSubstractFromAmount = "[Token / Send] Substract From Amount"
        case sendConfirmScreenOpened = "[Token / Send] Confirm Screen Opened"
        case sendScreenReopened = "[Token / Send] Screen Reopened"
        case sendTransactionSentScreenOpened = "[Token / Send] Transaction Sent Screen Opened"
        case sendButtonShare = "[Token / Send] Button - Share"
        case sendButtonExplore = "[Token / Send] Button - Explore"
        case sendNoticeTransactionDelaysArePossible = "[Token / Send] Notice - Transaction Delays Are Possible"
        case sendErrorTransactionRejected = "[Token / Send] Error - Transaction Rejected"
        case sendButtonClose = "[Token / Send] Button - Close"

        case topupScreenOpened = "[Token / Topup] Top Up Screen Opened"
        case p2PScreenOpened = "[Token / Topup] P2P Screen Opened"
        case withdrawScreenOpened = "[Token / Withdraw] Withdraw Screen Opened"
        case buttonUnlockAllWithBiometrics = "[Main Screen] Button - Unlock All With Biometrics"
        case buttonUnlockWithCardScan = "[Main Screen] Button - Unlock With Card Scan"
        case buttonEditWalletTapped = "[Main Screen] Button - Edit Wallet Tapped"
        case buttonDeleteWalletTapped = "[Main Screen] Button - Delete Wallet Tapped"
        case settingsButtonChat = "[Settings] Button - Chat"
        case settingsButtonManageTokens = "[Settings] Button - Manage Tokens"
        case buttonWalletConnect = "[Settings] Button - Wallet Connect"
        case buttonStartWalletConnectSession = "[Settings] Button - Start Wallet Connect Session"
        case buttonStopWalletConnectSession = "[Settings] Button - Stop Wallet Connect Session"
        case buttonCardSettings = "[Settings] Button - Card Settings"
        case buttonAppSettings = "[Settings] Button - App Settings"
        case buttonCreateBackup = "[Settings] Button - Create Backup"
        case buttonSocialNetwork = "[Settings] Button - Social Network"
        case buttonScanNewCardSettings = "[Settings] Button - Scan New Card"
        case buttonFactoryReset = "[Settings / Card Settings] Button - Factory Reset"
        case factoryResetFinished = "[Settings / Card Settings] Factory Reset Finished"
        case factoryResetCancelled = "[Settings / Card Settings] Factory Reset Cancelled"
        case buttonChangeUserCode = "[Settings / Card Settings] Button - Change User Code"
        case userCodeChanged = "[Settings / Card Settings] User Code Changed"
        case buttonChangeSecurityMode = "[Settings / Card Settings] Button - Change Security Mode"
        case securityModeChanged = "[Settings / Card Settings] Security Mode Changed"
        case saveUserWalletSwitcherChanged = "[Settings / App Settings] Save Wallet Switcher Changed"
        case saveAccessCodeSwitcherChanged = "[Settings / App Settings] Save Access Code Switcher Changed"
        case hideBalanceChanged = "[Settings / App Settings] Hide Balance Changed"
        case settingsNoticeEnableBiometrics = "[Settings / App Settings] Notice - Enable Biometric"
        case buttonEnableBiometricAuthentication = "[Settings / App Settings] Button - Enable Biometric Authentication"
        case mainCurrencyChanged = "[Settings / App Settings] Main Currency Changed"
        case walletConnectScreenOpened = "[Wallet Connect] WC Screen Opened"
        case newSessionEstablished = "[Wallet Connect] New Session Established"
        case sessionDisconnected = "[Wallet Connect] Session Disconnected"
        case requestHandled = "[Wallet Connect] Request Handled"
        case chatScreenOpened = "[Chat] Chat Screen Opened"
        case settingsScreenOpened = "[Settings] Settings Screen Opened"

        // MARK: - Referral program

        case referralScreenOpened = "[Referral Program] Referral Screen Opened"
        case referralButtonParticipate = "[Referral Program] Button - Participate"
        case referralButtonCopyCode = "[Referral Program] Button - Copy"
        case referralButtonShareCode = "[Referral Program] Button - Share"
        case referralButtonOpenTos = "[Referral Program] Link - TaC"

        // MARK: - Swap

        case swapScreenOpenedSwap = "[Swap] Swap Screen Opened"
        case swapSendTokenBalanceClicked = "[Swap] Send Token Balance Clicked"
        case swapChooseTokenScreenOpened = "[Swap] Choose Token Screen Opened"
        case swapChooseTokenScreenResult = "[Swap] Choose Token Screen Result"
        case swapSearchedTokenClicked = "[Swap] Searched Token Clicked"
        case swapButtonSwap = "[Swap] Button - Swap"
        case swapButtonGivePermission = "[Swap] Button - Give permission"
        case swapButtonPermissionApprove = "[Swap] Button - Permission Approve"
        case swapButtonPermissionCancel = "[Swap] Button - Permission Cancel"
        case swapButtonPermitAndSwap = "[Swap] Button - Permit and Swap"
        case swapButtonSwipe = "[Swap] Button - Swipe"
        case swapSwapInProgressScreenOpened = "[Swap] Swap in Progress Screen Opened"

        case swapProviderClicked = "[Swap] Provider Clicked"
        case swapProviderChosen = "[Swap] Provider Chosen"
        case swapButtonStatus = "[Swap] Button - Status"
        case swapButtonExplore = "[Swap] Button - Explore"
        case swapNoticeNoAvailableTokensToSwap = "[Swap] Notice - No Available Tokens To Swap"
        case swapNoticeExchangeRateHasExpired = "[Swap] Notice - Exchange Rate Has Expired"
        case swapNoticeNotEnoughFee = "[Swap] Notice - Not Enough Fee"
        case swapNoticeExpressError = "[Swap] Notice - Express Error"

        // MARK: - Seed phrase

        case onboardingSeedButtonOtherCreateWalletOptions = "[Onboarding / Create Wallet] Button - Other Options"
        case onboarindgSeedButtonGenerateSeedPhrase = "[Onboarding / Seed Phrase] Button - Generate Seed Phrase"
        case onboardingSeedButtonImportWallet = "[Onboarding / Seed Phrase] Button - Import Wallet"
        case onboardingSeedButtonReadMore = "[Onboarding / Seed Phrase] Button - Read More"
        case onboardingSeedButtonImport = "[Onboarding / Seed Phrase] Button - Import"

        case onboardingSeedIntroScreenOpened = "[Onboarding / Seed Phrase] Seed Intro Screen Opened"
        case onboardingSeedGenerationScreenOpened = "[Onboarding / Seed Phrase] Seed Generation Screen Opened"
        case onboardingSeedCheckingScreenOpened = "[Onboarding / Seed Phrase] Seed Checking Screen Opened"
        case onboardingSeedImportScreenOpened = "[Onboarding / Seed Phrase] Import Seed Phrase Screen Opened"

        case onboardingSeedScreenCapture = "[Onboarding / Seed Phrase] Screen Capture"

        // MARK: Express

        case tokenSwapStatus = "[Token] Swap Status"
        case tokenSwapStatusScreenOpened = "[Token] Swap Status Opened"
        case tokenButtonGoToProvider = "[Token] Button - Go To Provider"
        case tokenButtonGoToToken = "[Token] Button - Go to Token"

        // MARK: - App settings

        case appSettingsAppThemeSwitched = "[Settings / App Settings] App Theme Swithed"

        // MARK: - Card settings

        case cardSettingsButtonAccessCodeRecovery = "[Settings / Card Settings] Button - Access Code Recovery"
        case cardSettingsAccessCodeRecoveryChanged = "[Settings / Card Settings] Access Code Recovery Changed"

        fileprivate static var nfcError: String {
            "nfc_error"
        }

        // MARK: - Notifications

        case mainNoticeBackupWalletTapped = "[Main Screen] Notice - Backup Your Wallet Tapped"
        case mainNoticeScanYourCardTapped = "[Main Screen] Notice - Scan Your Card Tapped"
        case mainNoticeNetworksUnreachable = "[Main Screen] Notice - Networks  Unreachable"
        case mainNoticeCardSignedTransactions = "[Main Screen] Notice - Card Signed Transactions"
        case mainNoticeProductSampleCard = "[Main Screen] Notice - Product Sample Card"
        case mainNoticeTestnetCard = "[Main Screen] Notice - Testnet Card"
        case mainNoticeDemoCard = "[Main Screen] Notice - Demo Card"
        case mainNoticeOldCard = "[Main Screen] Notice - Old Card"
        case mainNoticeDevelopmentCard = "[Main Screen] Notice - Development Card"
        case mainNoticeMissingAddress = "[Main Screen] Notice - Missing Addresses"
        case mainNoticeWalletUnlock = "[Main Screen] Notice - Wallet Unlock"
        case mainNoticeWalletUnlockTapped = "[Main Screen] Notice - Wallet Unlock Tapped"
        case mainNoticeBackupYourWallet = "[Main Screen] Notice - Backup Your Wallet"
        case mainNoticeRateTheApp = "[Main Screen] Notice - Rate The App"
        case mainNoticeBackupErrors = "[Main Screen] Notice - Backup Errors"
        case tokenNoticeNetworkUnreachable = "[Token] Notice - Network Unreachable"
        case tokenNoticeNotEnoughFee = "[Token] Notice - Not Enough Fee"

        // MARK: - BlockchainSdk exceptions

        case blockchainSdkException = "[BlockchainSdk] Exception"

        // MARK: - Health check

        case healthCheckPolkadotAccountReset = "[Token] Polkadot Account Reset"
        case healthCheckPolkadotImmortalTransactions = "[Token] Polkadot Immortal Transactions"

        // MARK: - Promotion

        case promotionBannerAppeared = "[Promotion] Notice - Promotion Banner"
        case promotionBannerClicked = "[Promotion] Promo Banner Clicked"

        // MARK: - Errors

        case cantScanTheCard = "[Errors] Cant Scan The Card"
        case cantScanTheCardButtonBlog = "[Errors] Cant Scan The Card - Button Blog"
        case cantScanTheCardTryAgainButton = "[Errors] Cant Scan The Card - Try Again Button"

        // MARK: - Promo

        case promoChangellyActivity = "[Promo] Changelly Activity"

        // MARK: - Push notifications

        case pushButtonAllow = "[Push] Button - Allow"
        case pushButtonPostpone = "[Push] Button - Later"
        case pushPermissionStatus = "[Push] Permission Status"

        // MARK: - Staking

        case stakingInfoScreenOpened = "[Staking] Staking Info Screen Opened"
        case stakingLinkWhatIsStaking = "[Staking] Link - What Is Staking"
        case stakingButtonStake = "[Staking] Button - Stake"
        case stakingAmountScreenOpened = "[Staking] Amount Screen Opened"
        case stakingScreenReopened = "[Staking] Screen Reopened"
        case stakingButtonMax = "[Staking] Button - Max"
        case stakingButtonNext = "[Staking] Button - Next"
        case stakingButtonCancel = "[Staking] Button - Cancel"
        case stakingButtonValidator = "[Staking] Button - Validator"
        case stakingValidatorChosen = "[Staking] Validator Chosen"
        case stakingStakeInProgressScreenOpened = "[Staking] Stake In Progress Screen Opened"
        case stakingButtonRewards = "[Staking] Button - Rewards"
        case stakingRewardScreenOpened = "[Staking] Reward Screen Opened"
        case stakingButtonClaim = "[Staking] Button - Claim"
        case stakingButtonRestake = "[Staking] Button - Restake"
        case stakingButtonUnstake = "[Staking] Button - Unstake"
        case stakingButtonWithdraw = "[Staking] Button - Withdraw"
        case stakingConfirmationScreenOpened = "[Staking] Confirmation Screen Opened"
        case stakingErrors = "[Staking] Errors"
        case stakingErrorTransactionRejected = "[Staking] Error - Transaction Rejected"
        case stakingAppErrors = "[Staking] App Errors"
        case stakingSelectedCurrency = "[Staking] Selected Currency"
        case stakingButtonShare = "[Staking] Button - Share"
        case stakingButtonExplore = "[Staking] Button - Explore"

        // MARK: - Markets

        case marketsScreenOpened = "[Markets] Markets Screen Opened"
        case marketsTokensSort = "[Markets] Sort By"
        case marketsDataError = "[Markets] Data Error"

        // MARK: - Markets / Chart

        case marketsChartScreenOpened = "[Markets / Chart] Token Chart Screen Opened"
        case marketsChartButtonPeriod = "[Markets / Chart] Button - Period"
        case marketsChartButtonReadMore = "[Markets / Chart] Button - Read More"
        case marketsChartButtonLinks = "[Markets / Chart] Button - Links"
        case marketsChartButtonAddToPortfolio = "[Markets / Chart] Button - Add To Portfolio"
        case marketsChartWalletSelected = "[Markets / Chart] Wallet Selected"
        case marketsChartTokenNetworkSelected = "[Markets / Chart] Token Network Selected"
        case marketsChartButtonBuy = "[Markets / Chart] Button - Buy"
        case marketsChartButtonReceive = "[Markets / Chart] Button - Receive"
        case marketsChartButtonSwap = "[Markets / Chart] Button - Swap"
        case marketsChartDataError = "[Markets / Chart] Data Error"

        // MARK: - Manage Tokens

        case manageTokensScreenOpened = "[Manage Tokens] Manage Tokens Screen Opened"
        case manageTokensTokenIsNotFound = "[Manage Tokens] Token Is Not Found"
        case manageTokensSwitcherChanged = "[Manage Tokens] Token Switcher Changed"
        case manageTokensButtonLater = "[Manage Tokens] Button - Later"
        case manageTokensTokenAdded = "[Manage Tokens] Token Added"

        case manageTokensSearched = "[Manage Tokens] Token Searched"
        case manageTokensWalletSelected = "[Manage Tokens] Wallet Selected"

        // MARK: - Manange Tokens / Custom

        case manageTokensButtonCustomToken = "[Manage Tokens / Custom] Button - Custom Token"
        case manageTokensCustomTokenScreenOpened = "[Manage Tokens / Custom] Custom Token Screen Opened"
        case manageTokensCustomTokenWasAdded = "[Manage Tokens / Custom] Custom Token Was Added"
        case manageTokensCustomTokenNetworkSelected = "[Manage Tokens / Custom] Custom Token Network Selected"
        case manageTokensCustomTokenDerivationSelected = "[Manage Tokens / Custom] Custom Token Derivation Selected"
        case manageTokensCustomTokenAddress = "[Manage Tokens / Custom] Custom Token Address"
        case manageTokensCustomTokenName = "[Manage Tokens / Custom] Custom Token Name"
        case manageTokensCustomTokenSymbol = "[Manage Tokens / Custom] Custom Token Symbol"
        case manageTokensCustomTokenDecimals = "[Manage Tokens / Custom] Custom Token Decimals"
    }
}
