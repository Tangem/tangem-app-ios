//
//  UserWalletConfigFeatures.swift
//  Tangem
//
//  Created by Alexander Osokin on 29.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

enum UserWalletFeature: Int, CaseIterable { // TODO: Add comments
    case accessCode
    case passcode
    case longTap
    case longHashes
    case backup
    case twinning
    case hdWallets

    case send
    case receive

    case topup
    case withdrawal
    case exchange
    case staking

    case walletConnect
    case multiCurrency
    case resetToFactory
    /// Count signed hashes to display warning for user if card already sign hashes in the past.
    case signedHashesCounter
    case onlineImage
    /// Is wallet allowed to participate in referral program
    case referralProgram

    /// Synchronize tokens between devices using`userWalletId`
    /// Only for issued cards with multiple wallets
    case tokenSynchronization

    case swapping
    case displayHashesCount
    case transactionHistory

    case accessCodeRecoverySettings

    case promotion
}

extension UserWalletFeature {
    enum Availability {
        case available
        case hidden
        case disabled(localizedReason: String? = nil)

        var disabledLocalizedReason: String? {
            if case .disabled(let reason) = self, let reason = reason {
                return reason
            }

            return nil
        }

        var isAvailable: Bool {
            if case .available = self {
                return true
            }

            return false
        }

        var isHidden: Bool {
            if case .hidden = self {
                return true
            }

            return false
        }

        static var demoStub: Availability {
            .disabled(localizedReason: Localization.alertDemoFeatureDisabled)
        }
    }
}
