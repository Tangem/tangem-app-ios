//
//  TokenNotificationEvent.swift
//  Tangem
//
//  Created by Andrew Son on 30/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

enum TokenNotificationEvent: Hashable {
    case networkUnreachable(currencySymbol: String)
    case someNetworksUnreachable(currencySymbols: [String])
    case rentFee(rentMessage: String)
    case noAccount(message: String)
    case existentialDepositWarning(message: String)
    case notEnoughFeeForTransaction(configuration: NotEnoughFeeConfiguration)
    case bnbBeaconChainRetirement
    case hasUnfulfilledRequirements(configuration: UnfulfilledRequirementsConfiguration)
    case staking(tokenIconInfo: TokenIconInfo, earnUpToFormatted: String)
    case manaLevel(currentMana: String, maxMana: String)
    case maticMigration
    case kaspaTokensBeta

    static func event(
        for reason: TransactionSendAvailabilityProvider.SendingRestrictions,
        isFeeCurrencyPurchaseAllowed: Bool
    ) -> TokenNotificationEvent? {
        switch reason {
        case .zeroWalletBalance,
             .hasPendingTransaction,
             .blockchainUnreachable,
             .cantSignLongTransactions,
             .oldCard:
            return nil
        case .zeroFeeCurrencyBalance(let eventConfiguration):
            let configuration = NotEnoughFeeConfiguration(
                isFeeCurrencyPurchaseAllowed: isFeeCurrencyPurchaseAllowed,
                eventConfiguration: eventConfiguration
            )
            return .notEnoughFeeForTransaction(configuration: configuration)
        }
    }
}

extension TokenNotificationEvent: NotificationEvent {
    var title: NotificationView.Title {
        switch self {
        case .networkUnreachable:
            return .string(Localization.warningNetworkUnreachableTitle)
        case .someNetworksUnreachable:
            return .string(Localization.warningSomeNetworksUnreachableTitle)
        case .rentFee:
            return .string(Localization.warningRentFeeTitle)
        case .noAccount:
            return .string(Localization.warningNoAccountTitle)
        case .existentialDepositWarning:
            return .string(Localization.warningExistentialDepositTitle)
        case .notEnoughFeeForTransaction(let configuration):
            return .string(Localization.warningSendBlockedFundsForFeeTitle(configuration.eventConfiguration.feeAmountTypeName))
        case .bnbBeaconChainRetirement:
            return .string(Localization.warningBeaconChainRetirementTitle)
        case .hasUnfulfilledRequirements(configuration: .missingHederaTokenAssociation):
            return .string(Localization.warningHederaMissingTokenAssociationTitle)
        case .hasUnfulfilledRequirements(configuration: .incompleteKaspaTokenTransaction):
            return .string(Localization.warningKaspaUnfinishedTokenTransactionTitle)
        case .staking(_, let earnUpToFormatted):
            return .string(Localization.tokenDetailsStakingBlockTitle(earnUpToFormatted))
        case .manaLevel:
            return .string(Localization.koinosManaLevelTitle)
        case .maticMigration:
            return .string(Localization.warningMaticMigrationTitle)
        case .kaspaTokensBeta:
            return .string("")
        }
    }

    var description: String? {
        switch self {
        case .networkUnreachable:
            return Localization.warningNetworkUnreachableMessage
        case .someNetworksUnreachable:
            return Localization.warningSomeNetworksUnreachableMessage
        case .rentFee(let message):
            return message
        case .noAccount(let message):
            return message
        case .existentialDepositWarning(let message):
            return message
        case .notEnoughFeeForTransaction(let configuration):
            return Localization.warningSendBlockedFundsForFeeMessage(
                configuration.eventConfiguration.transactionAmountTypeName,
                configuration.eventConfiguration.networkName,
                configuration.eventConfiguration.transactionAmountTypeName,
                configuration.eventConfiguration.feeAmountTypeName,
                configuration.eventConfiguration.feeAmountTypeCurrencySymbol
            )
        case .bnbBeaconChainRetirement:
            return Localization.warningBeaconChainRetirementContent
        case .hasUnfulfilledRequirements(configuration: .missingHederaTokenAssociation(let associationFee)):
            guard let associationFee else {
                return Localization.warningHederaMissingTokenAssociationMessageBrief
            }

            return Localization.warningHederaMissingTokenAssociationMessage(
                associationFee.formattedValue,
                associationFee.currencySymbol
            )
        case .hasUnfulfilledRequirements(configuration: .incompleteKaspaTokenTransaction(let revealTransaction)):
            return Localization.warningKaspaUnfinishedTokenTransactionMessage(
                revealTransaction.formattedValue,
                revealTransaction.currencySymbol
            )
        case .staking:
            return Localization.stakingNotificationEarnRewardsText
        case .manaLevel(let currentMana, let maxMana):
            return Localization.koinosManaLevelDescription(currentMana, maxMana)
        case .maticMigration:
            return Localization.warningMaticMigrationMessage
        case .kaspaTokensBeta:
            return nil
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .networkUnreachable,
             .someNetworksUnreachable,
             .rentFee,
             .existentialDepositWarning,
             .noAccount,
             .bnbBeaconChainRetirement,
             .manaLevel,
             .maticMigration,
             .kaspaTokensBeta:
            return .secondary
        // One white notification will be added later
        case .notEnoughFeeForTransaction,
             .hasUnfulfilledRequirements(configuration: .missingHederaTokenAssociation),
             .hasUnfulfilledRequirements(configuration: .incompleteKaspaTokenTransaction),
             .staking:
            return .primary
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .networkUnreachable,
             .someNetworksUnreachable,
             .bnbBeaconChainRetirement,
             .maticMigration,
             .kaspaTokensBeta:
            return .init(iconType: .image(Assets.attention.image))
        case .rentFee, .noAccount, .existentialDepositWarning, .manaLevel:
            return .init(iconType: .image(Assets.blueCircleWarning.image))
        case .notEnoughFeeForTransaction(let configuration):
            return .init(iconType: .image(Image(configuration.eventConfiguration.feeAmountTypeIconName)))
        case .hasUnfulfilledRequirements(configuration: .missingHederaTokenAssociation):
            return .init(iconType: .image(Tokens.hederaFill.image))
        case .hasUnfulfilledRequirements(configuration: .incompleteKaspaTokenTransaction):
            return .init(iconType: .image(Assets.redCircleWarning.image))
        case .staking(let tokenIconInfo, _):
            return .init(iconType: .icon(tokenIconInfo))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .noAccount,
             .rentFee,
             .existentialDepositWarning,
             .staking,
             .manaLevel,
             .maticMigration,
             .kaspaTokensBeta:
            return .info
        case .networkUnreachable,
             .someNetworksUnreachable,
             .notEnoughFeeForTransaction,
             .bnbBeaconChainRetirement,
             .hasUnfulfilledRequirements(configuration: .missingHederaTokenAssociation),
             .hasUnfulfilledRequirements(configuration: .incompleteKaspaTokenTransaction):
            return .warning
        }
    }

    var isDismissable: Bool {
        switch self {
        case .rentFee,
             .hasUnfulfilledRequirements(configuration: .incompleteKaspaTokenTransaction):
            return true
        case .networkUnreachable,
             .someNetworksUnreachable,
             .existentialDepositWarning,
             .notEnoughFeeForTransaction,
             .noAccount,
             .bnbBeaconChainRetirement,
             .hasUnfulfilledRequirements(configuration: .missingHederaTokenAssociation),
             .staking,
             .manaLevel,
             .maticMigration,
             .kaspaTokensBeta:
            return false
        }
    }

    var buttonAction: NotificationButtonAction? {
        switch self {
        // One notification with button action will be added later
        case .networkUnreachable,
             .someNetworksUnreachable,
             .rentFee,
             .existentialDepositWarning,
             .noAccount,
             .bnbBeaconChainRetirement,
             .manaLevel,
             .maticMigration,
             .kaspaTokensBeta:
            return nil
        case .notEnoughFeeForTransaction(let configuration):
            let eventConfig = configuration.eventConfiguration
            let currencySymbol = eventConfig.currencyButtonTitle ?? eventConfig.feeAmountTypeCurrencySymbol
            if configuration.isFeeCurrencyPurchaseAllowed {
                return .init(.openFeeCurrency(currencySymbol: currencySymbol))
            }

            return nil
        case .hasUnfulfilledRequirements(.missingHederaTokenAssociation):
            return .init(.addHederaTokenAssociation)
        case .hasUnfulfilledRequirements(configuration: .incompleteKaspaTokenTransaction):
            return .init(.retryKaspaTokenTransaction)
        case .staking:
            return .init(.stake)
        }
    }
}

// MARK: - Auxiliary types

extension TokenNotificationEvent {
    struct NotEnoughFeeConfiguration: Hashable {
        let isFeeCurrencyPurchaseAllowed: Bool
        let eventConfiguration: TransactionSendAvailabilityProvider.SendingRestrictions.NotEnoughFeeConfiguration
    }

    enum UnfulfilledRequirementsConfiguration: Hashable {
        /// `formattedValue` is a formatted string for the value denominated in HBARs.
        struct HederaTokenAssociationFee: Hashable {
            let formattedValue: String
            let currencySymbol: String
        }

        /// `onTransactionDiscard` callback is intentionally ignored by `Equatable` and `Hashable` implementations.
        struct KaspaTokenRevealTransaction: Hashable {
            let formattedValue: String
            let currencySymbol: String

            /// Use for only analytics parameter value
            let blockchainName: String

            let onTransactionDiscard: () -> Void

            static func == (lhs: Self, rhs: Self) -> Bool {
                return lhs.formattedValue == rhs.formattedValue && lhs.currencySymbol == rhs.currencySymbol
            }

            func hash(into hasher: inout Hasher) {
                hasher.combine(formattedValue)
                hasher.combine(currencySymbol)
            }
        }

        /// `associationFee` fetched asynchronously and therefore may be absent in some cases.
        case missingHederaTokenAssociation(associationFee: HederaTokenAssociationFee?)
        case incompleteKaspaTokenTransaction(revealTransaction: KaspaTokenRevealTransaction)
        @available(*, unavailable, message: "Token trust lines support not implemented yet")
        case missingTokenTrustline
    }
}

// MARK: Analytics info

extension TokenNotificationEvent {
    var analyticsEvent: Analytics.Event? {
        switch self {
        case .networkUnreachable: return .tokenNoticeNetworkUnreachable
        case .someNetworksUnreachable: return .mainNoticeNetworksUnreachable
        case .rentFee: return nil
        case .noAccount: return nil
        case .existentialDepositWarning: return nil
        case .notEnoughFeeForTransaction: return .tokenNoticeNotEnoughFee
        case .bnbBeaconChainRetirement: return nil
        case .hasUnfulfilledRequirements(configuration: .missingHederaTokenAssociation): return nil
        case .hasUnfulfilledRequirements(configuration: .incompleteKaspaTokenTransaction): return .tokenNoticeRevealTransaction
        case .staking: return nil
        case .manaLevel: return nil
        case .maticMigration: return nil
        case .kaspaTokensBeta: return nil
        }
    }

    var analyticsParams: [Analytics.ParameterKey: String] {
        switch self {
        case .networkUnreachable(let currencySymbol):
            return [.token: currencySymbol]
        case .notEnoughFeeForTransaction(let configuration):
            return [.token: configuration.eventConfiguration.feeAmountTypeCurrencySymbol]
        case .someNetworksUnreachable(let networks):
            return [.tokens: networks.joined(separator: ", ")]
        case .hasUnfulfilledRequirements(configuration: .incompleteKaspaTokenTransaction(let revealTransaction)):
            return [.token: revealTransaction.currencySymbol, .blockchain: revealTransaction.blockchainName]
        case .rentFee,
             .noAccount,
             .existentialDepositWarning,
             .bnbBeaconChainRetirement,
             .hasUnfulfilledRequirements(configuration: .missingHederaTokenAssociation),
             .staking,
             .manaLevel,
             .maticMigration,
             .kaspaTokensBeta:
            return [:]
        }
    }

    /// Determine if analytics event should be sent only once and tracked by service
    var isOneShotAnalyticsEvent: Bool { false }

    var analyticsEventWhenDismissAction: Analytics.Event? {
        switch self {
        case .hasUnfulfilledRequirements(configuration: .incompleteKaspaTokenTransaction): return .tokenButtonRevealCancel
        default:
            // Now used only incompleteKaspaTokenTransaction
            return nil
        }
    }
}
