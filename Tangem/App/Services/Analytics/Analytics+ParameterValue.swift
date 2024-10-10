//
//  AnalyticsEvent.swift
//  Tangem
//
//  Created by Andrew Son on 24/10/22.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

extension Analytics {
    enum ParameterValue: String {
        case welcome
        case walletOnboarding = "wallet_onboarding"
        case ok = "Ok"
        case error = "Error"
        case on = "On"
        case off = "Off"
        case yes = "Yes"
        case no = "No"
        case full = "Full"
        case null = "Null"
        case empty = "Empty"
        case mainToken = "Main Token"
        case customToken = "Custom Token"
        case noRate = "No Rate"
        case blockchainError = "Blockchain Error"
        case multicurrency = "Multicurrency"
        case accessCode = "Access Code"
        case longTap = "Long tap"
        case passcode = "Passcode"
        case market = "Market"
        case chart = "Chart"
        case blocks = "Blocks"

        case card = "Card"
        case ring = "Ring"

        case main = "Main"
        case token = "Token"
        case manageTokens = "Manage Tokens"
        case introduction = "Introduction"
        case onboarding = "Onboarding"
        case settings = "Settings"
        case signIn = "Sign In"
        case receive = "Receive"
        case stories = "Stories"

        case transactionSourceSend = "Send"
        case transactionSourceSwap = "Swap"
        case transactionSourceApprove = "Approve"
        case transactionSourceWalletConnect = "WalletConnect"
        case transactionSourceSell = "Sell"
        case transactionSourceStaking = "Staking"

        case transactionFeeFixed = "Fixed"
        case transactionFeeMin = "Min"
        case transactionFeeNormal = "Normal"
        case transactionFeeMax = "Max"
        case transactionFeeCustom = "Custom"

        case signInTypeBiometrics = "Biometric"

        case walletCreationTypePrivateKey = "Private Key"
        case walletCreationTypeNewSeed = "New Seed"
        case walletCreationTypeSeedImport = "Seed Import"

        case enabled = "Enabled"
        case disabled = "Disabled"
        case reset = "Reset"
        case allow = "Allow"
        case cancel = "Cancel"

        case errorCode = "Error Code"

        case oneTransactionApprove = "Current Transaction"
        case unlimitedApprove = "Unlimited"

        // destination address entered
        case destinationAddressSourceQrCode = "QRCode"
        case destinationAddressSourcePasteButton = "PasteButton"
        case destinationAddressSourcePastePopup = "PastePopup"
        case destinationAddressSourceRecentAddress = "RecentAddress"
        case destinationAddressSourceMyWallet = "MyWallet"

        case success = "Success"
        case fail = "Fail"

        // SelectedCurrency
        case selectedCurrencyApp = "App Currency"

        // Client Type
        case old = "Old"
        case new = "New"

        case sortTypeByBalance = "By Balance"
        case sortTypeManual = "Manually"

        case balance = "Balance"

        // Transaction is sent
        case sent = "Sent"

        // MARK: - Express

        case status = "Status"

        // CEX statuses
        case inProgress = "In Progress"
        case done = "Done"
        case kyc = "KYC"
        case refunded = "Refunded"
        case canceled = "Canceled"

        // App theme
        case system = "System"
        case light = "Light"
        case dark = "Dark"

        // MARK: - Send screens

        case address = "Address"
        case amount = "Amount"
        case fee = "Fee"
        case summary = "Summary"
        case finish = "Finish"

        // MARK: - Actions

        case scan = "tap_scan_task"
        case sendTx = "send_transaction"
        case pushTx = "push_transaction"
        case walletConnectSign = "wallet_connect_personal_sign"
        case walletConnectTxSend = "wallet_connect_tx_sign"
        case readPinSettings = "read_pin_settings"
        case changeSecOptions = "change_sec_options"
        case createWallet = "create_wallet"
        case purgeWallet = "purge_wallet"
        case deriveKeys = "derive_keys"
        case preparePrimary = "prepare_primary"
        case readPrimary = "read_primary"
        case addbackup = "add_backup"
        case proceedBackup = "proceed_backup"

        // MARK: - Promotion banners        case ring = "Ring"

        case clicked = "Clicked"
        case closed = "Closed"

        // MARK: - Promo

        case recommended = "Recommended"
        case native = "Native"

        // MARK: - Rate the app response

        /// App store review (`RateAppResponse.positive`).
        case appStoreReview = "Rate"
        /// Feedback email (`RateAppResponse.negative`).
        case feedbackEmail = "Feedback"
        /// The review sheet dismissed w/o further interactions (`RateAppResponse.dismissed`).
        case appRateDismissed = "Close"

        // MARK: - Stake

        case stakeSourceStakeInfo = "Stake Info"
        case stakeSourceConfirmation = "Confirmation"
        case stakeSourceValidators = "Validators"

        case stakeActionStake = "Stake"
        case stakeActionUnstake = "Unstake"
        case stakeActionClaimRewards = "Claim Rewards"
        case stakeActionRestakeRewards = "Restake Rewards"
        case stakeActionWithdraw = "Withdraw"
        case stakeActionRestake = "Restake"
        case stakeActionClaimUnstaked = "Claim Unstaked"
        case stakeActionUnlockLocked = "Unlock Locked"
        case stakeActionStakeLocked = "Stake Locked"
        case stakeActionVote = "Vote"
        case stakeActionRevoke = "Revoke"
        case stakeActionVoteLocked = "Vote Locked"
        case stakeActionRevote = "Revote"
        case stakeActionRebond = "Rebond"
        case stakeActionMigrate = "Migrate"

        // MARK: - Common

        static func toggleState(for boolean: Bool) -> ParameterValue {
            return boolean ? .on : .off
        }

        static func affirmativeOrNegative(for boolean: Bool) -> ParameterValue {
            return boolean ? .yes : .no
        }
    }
}
