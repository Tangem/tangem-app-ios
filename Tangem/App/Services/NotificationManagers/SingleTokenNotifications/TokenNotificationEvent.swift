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
    case someNetworksUnreachable
    case rentFee(rentMessage: String)
    case noAccount(message: String)
    case existentialDepositWarning(message: String)
    case notEnoughFeeForTransaction(configuration: NotEnoughFeeConfiguration)
    case solanaHighImpact
    case bnbBeaconChainRetirement
    case hasUnfulfilledRequirements(configuration: UnfulfilledRequirementsConfiguration)

    static func event(
        for reason: TransactionSendAvailabilityProvider.SendingRestrictions,
        isFeeCurrencyPurchaseAllowed: Bool
    ) -> TokenNotificationEvent? {
        switch reason {
        case .zeroWalletBalance, .hasPendingTransaction, .blockchainUnreachable, .cantSignLongTransactions:
            return nil
        case .zeroFeeCurrencyBalance(let eventConfiguration):
            let configuration = NotEnoughFeeConfiguration(
                isFeeCurrencyPurchaseAllowed: isFeeCurrencyPurchaseAllowed,
                eventConfiguration: eventConfiguration
            )
            return .notEnoughFeeForTransaction(configuration: configuration)
        }
    }

    var buttonAction: NotificationButtonActionType? {
        switch self {
        // One notification with button action will be added later
        case .networkUnreachable,
             .someNetworksUnreachable,
             .rentFee,
             .existentialDepositWarning,
             .noAccount,
             .solanaHighImpact,
             .bnbBeaconChainRetirement:
            return nil
        case .notEnoughFeeForTransaction(let configuration):
            let eventConfig = configuration.eventConfiguration
            return configuration.isFeeCurrencyPurchaseAllowed
                ? .openFeeCurrency(currencySymbol: eventConfig.currencyButtonTitle ?? eventConfig.feeAmountTypeCurrencySymbol)
                : nil
        case .hasUnfulfilledRequirements(.missingHederaTokenAssociation):
            return .addHederaTokenAssociation
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
        case .solanaHighImpact:
            return .string(Localization.warningSolanaFeeTitle)
        case .bnbBeaconChainRetirement:
            return .string(Localization.warningBnbRetirementTitle)
        case .hasUnfulfilledRequirements(configuration: .missingHederaTokenAssociation):
            return .string(Localization.warningHederaMissingTokenAssociationTitle)
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
        case .solanaHighImpact:
            return Localization.warningSolanaFeeMessage
        case .bnbBeaconChainRetirement:
            return Localization.warningBnbRetirementMessage
        case .hasUnfulfilledRequirements(configuration: .missingHederaTokenAssociation(let associationFee)):
            guard let associationFee else {
                return Localization.warningHederaMissingTokenAssociationMessageBrief
            }

            return Localization.warningHederaMissingTokenAssociationMessage(
                associationFee.formattedValue,
                associationFee.currencySymbol
            )
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .networkUnreachable,
             .someNetworksUnreachable,
             .rentFee,
             .existentialDepositWarning,
             .noAccount,
             .solanaHighImpact,
             .bnbBeaconChainRetirement:
            return .secondary
        // One white notification will be added later
        case .notEnoughFeeForTransaction,
             .hasUnfulfilledRequirements(configuration: .missingHederaTokenAssociation):
            return .primary
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .networkUnreachable, .someNetworksUnreachable, .solanaHighImpact, .bnbBeaconChainRetirement:
            return .init(iconType: .image(Assets.attention.image))
        case .rentFee, .noAccount, .existentialDepositWarning:
            return .init(iconType: .image(Assets.blueCircleWarning.image))
        case .notEnoughFeeForTransaction(let configuration):
            return .init(iconType: .image(Image(configuration.eventConfiguration.feeAmountTypeIconName)))
        case .hasUnfulfilledRequirements(configuration: .missingHederaTokenAssociation):
            return .init(iconType: .image(Tokens.hederaFill.image))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .noAccount,
             .rentFee,
             .existentialDepositWarning:
            return .info
        case .networkUnreachable,
             .someNetworksUnreachable,
             .notEnoughFeeForTransaction,
             .solanaHighImpact,
             .bnbBeaconChainRetirement,
             .hasUnfulfilledRequirements(configuration: .missingHederaTokenAssociation):
            return .warning
        }
    }

    var isDismissable: Bool {
        switch self {
        case .rentFee:
            return true
        case .networkUnreachable,
             .someNetworksUnreachable,
             .existentialDepositWarning,
             .notEnoughFeeForTransaction,
             .noAccount,
             .solanaHighImpact,
             .bnbBeaconChainRetirement,
             .hasUnfulfilledRequirements(configuration: .missingHederaTokenAssociation):
            return false
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

        /// `associationFee` fetched asynchronously and therefore may be absent in some cases.
        case missingHederaTokenAssociation(associationFee: HederaTokenAssociationFee?)
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
        case .solanaHighImpact: return nil
        case .bnbBeaconChainRetirement: return nil
        case .hasUnfulfilledRequirements(configuration: .missingHederaTokenAssociation): return nil
        }
    }

    var analyticsParams: [Analytics.ParameterKey: String] {
        switch self {
        case .networkUnreachable(let currencySymbol):
            return [.token: currencySymbol]
        case .notEnoughFeeForTransaction(let configuration):
            return [.token: configuration.eventConfiguration.feeAmountTypeCurrencySymbol]
        case .someNetworksUnreachable,
             .rentFee,
             .noAccount,
             .existentialDepositWarning,
             .solanaHighImpact,
             .bnbBeaconChainRetirement,
             .hasUnfulfilledRequirements(configuration: .missingHederaTokenAssociation):
            return [:]
        }
    }

    /// Determine if analytics event should be sent only once and tracked by service
    var isOneShotAnalyticsEvent: Bool { false }
}
