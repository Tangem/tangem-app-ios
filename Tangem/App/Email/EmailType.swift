//
//  EmailType.swift
//  Tangem
//
//  Created by Andrew Son on 18/02/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

enum EmailType {
    case negativeRateAppFeedback
    case failedToScanCard
    case failedToSendTx
    case failedToPushTx
    case appFeedback(subject: String)
    case activatedCard

    var emailSubject: String {
        switch self {
        case .negativeRateAppFeedback: return Localization.feedbackSubjectRateNegative
        case .failedToScanCard: return Localization.feedbackSubjectScanFailed
        case .failedToSendTx: return Localization.feedbackSubjectTxFailed
        case .appFeedback(let subject):
            return subject
        case .failedToPushTx: return Localization.feedbackSubjectTxPushFailed
        case .activatedCard: return Localization.feedbackSubjectPreActivatedWallet
        }
    }

    var emailPreface: String {
        switch self {
        case .negativeRateAppFeedback: return Localization.feedbackPrefaceRateNegative
        case .failedToScanCard: return Localization.feedbackPrefaceScanFailed
        case .failedToSendTx: return Localization.feedbackPrefaceTxFailed
        case .appFeedback, .activatedCard: return Localization.feedbackPrefaceSupport
        case .failedToPushTx: return Localization.feedbackPrefaceTxFailed
        }
    }

    var sentEmailAlertTitle: String {
        switch self {
        case .negativeRateAppFeedback: return Localization.alertNegativeAppRateSentTitle
        default: return Localization.alertAppFeedbackSentTitle
        }
    }

    var sentEmailAlertMessage: String {
        switch self {
        case .negativeRateAppFeedback: return Localization.alertNegativeAppRateSentMessage
        default: return Localization.alertAppFeedbackSentMessage
        }
    }

    var failedToSendAlertTitle: String {
        Localization.alertFailedToSendEmailTitle
    }

    func failedToSendAlertMessage(_ error: Error?) -> String {
        Localization.alertFailedToSendTransactionMessage(error?.localizedDescription ?? "Unknown error")
    }
}

struct EmailCollectedData {
    let type: EmailCollectedDataType
    let data: String

    static func separator(_ type: EmailCollectedDataType.SeparatorType) -> EmailCollectedData {
        EmailCollectedData(type: .separator(type), data: "")
    }
}

enum EmailCollectedDataType {
    case logs
    case card(CardData)
    case send(SendData)
    case staking(StakingData)
    case wallet(WalletData)
    case error
    case separator(SeparatorType)
    case token(TokenData)

    enum CardData: String {
        case cardId = "Card ID"
        case firmwareVersion = "Firmware version"
        case cardBlockchain = "Card Blockchain"
        case blockchain
        case derivationPath = "Derivation path"
        case token
        case userWalletId
        case linkedCardsCount = "Linked cards count"
        case backupCardsCount = "Backup cards count"
    }

    enum SendData: String {
        case sourceAddress = "Source address"
        case destinationAddress = "Destination address"
        case amount
        case fee
        case isFeeIncluded = "Is fee included"
        case transactionHex = "Transaction HEX"
        case pushingTxHash = "Pushing Transaction Hash"
        case pushingFee = "Pushing Transaction New Fee"
    }

    enum StakingData: String {
        case validatorName = "Validator Name"
        case validatorAddress = "Validator Address"
        case stakingAction = "Staking Action"
    }

    enum WalletData: String {
        case walletAddress = "Wallet address"
        case explorerLink = "Explorer link"
        case signedHashes = "Signed hashes"
        case walletManagerHost = "Host"
        case exceptionWalletManagerHost = "Exception Host"
        case outputsCount = "Outputs count"
        case derivationPath = "Derivation path"
        case hasSeedPhrase = "Has seed phrase"
    }

    enum TokenData: String {
        case contractAddress = "Contract address"
        case name = "Name"
        case id = "ID"
        case decimals = "Decimals"
    }

    enum SeparatorType: String {
        case dashes = "--------"
        case newLine = "\n"
    }

    var title: String {
        switch self {
        case .logs: return "Logs: "
        case .card(let data): return data.rawValue.capitalizingFirstLetter() + ": "
        case .send(let data): return data.rawValue.capitalizingFirstLetter() + ": "
        case .staking(let data): return data.rawValue.capitalizingFirstLetter() + ": "
        case .wallet(let data): return data.rawValue + ": "
        case .token(let data): return data.rawValue + ": "
        case .error: return "Error: "
        case .separator(let type): return type.rawValue
        }
    }
}
