//
//  PendingTransaction.swift
//  Tangem
//
//  Created by Andrew Son on 11/06/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct TransactionViewModel: Hashable, Identifiable {
    var id: ViewModelId { ViewModelId(hash: hash, index: index) }

    let hash: String

    var inProgress: Bool {
        status == .inProgress
    }

    var subtitleText: String {
        return timeFormatted ?? "-"
    }

    var formattedAmount: String? {
        switch transactionType {
        case .approve, .vote, .withdraw:
            return nil
        case .transfer, .swap, .operation, .unknownOperation, .stake, .unstake, .claimRewards:
            return amount
        }
    }

    var localizeDestination: String? {
        if status == .failed {
            return Localization.commonTransactionFailed
        }

        switch interactionAddress {
        case .user(let address):
            if isOutgoing {
                return Localization.transactionHistoryTransactionToAddress(address)
            } else {
                return Localization.transactionHistoryTransactionFromAddress(address)
            }
        case .contract(let address):
            return Localization.transactionHistoryContractAddress(address)
        case .multiple:
            if isOutgoing {
                return Localization.transactionHistoryTransactionToAddress(
                    Localization.transactionHistoryMultipleAddresses
                )
            } else {
                return Localization.transactionHistoryTransactionFromAddress(
                    Localization.transactionHistoryMultipleAddresses
                )
            }
        // Temp solution for Visa
        case .custom(let message):
            return message
        case .staking(let validator):
            return validator.flatMap { Localization.stakingValidator + ": " + $0 }
        }
    }

    var name: String {
        switch transactionType {
        case .transfer: Localization.commonTransfer
        case .swap: Localization.commonSwap
        case .approve: Localization.commonApproval
        case .unknownOperation: Localization.transactionHistoryOperation
        case .operation(name: let name): name
        case .stake: Localization.commonStake
        case .unstake: Localization.commonUnstake
        case .vote: Localization.stakingVote
        case .withdraw: Localization.stakingWithdraw
        case .claimRewards: Localization.commonClaimRewards
        }
    }

    var icon: Image {
        if status == .failed {
            return Assets.crossBig.image
        }

        switch transactionType {
        case .approve:
            return Assets.approve.image
        case .transfer, .swap, .operation, .unknownOperation:
            return isOutgoing ? Assets.arrowUpMini.image : Assets.arrowDownMini.image
        case .stake, .vote:
            return Assets.TokenItemContextMenu.menuStaking.image
        case .unstake, .withdraw:
            return Assets.unstakedIcon.image
        case .claimRewards:
            return Assets.dollarMini.image
        }
    }

    var iconColor: Color {
        switch status {
        case .inProgress:
            return Colors.Icon.accent
        case .confirmed:
            return Colors.Icon.informative
        case .failed:
            return Colors.Icon.warning
        }
    }

    var iconBackgroundColor: Color {
        switch status {
        case .inProgress: return Colors.Icon.accent.opacity(0.1)
        case .confirmed: return Colors.Background.secondary
        case .failed: return Colors.Icon.warning.opacity(0.1)
        }
    }

    var amountColor: Color {
        switch status {
        case .failed: return Colors.Text.warning
        default: return Colors.Text.primary1
        }
    }

    /// Index of an individual transaction within the parent transaction (if applicable).
    /// For example, a single EVM transaction may consist of multiple token transactions (with indices 0, 1, 2 and so on)
    private let index: Int
    private let interactionAddress: InteractionAddressType
    private let timeFormatted: String?
    private let amount: String
    private let isOutgoing: Bool
    private let transactionType: TransactionType
    private let status: Status

    init(
        hash: String,
        index: Int,
        interactionAddress: InteractionAddressType,
        timeFormatted: String?,
        amount: String,
        isOutgoing: Bool,
        transactionType: TransactionViewModel.TransactionType,
        status: TransactionViewModel.Status
    ) {
        self.hash = hash
        self.index = index
        self.interactionAddress = interactionAddress
        self.timeFormatted = timeFormatted
        self.amount = amount
        self.isOutgoing = isOutgoing
        self.transactionType = transactionType
        self.status = status
    }
}

extension TransactionViewModel {
    /// An opaque unique identity for use with the `Identifiable` protocol.
    struct ViewModelId: Hashable {
        fileprivate let hash: String
        fileprivate let index: Int
    }

    enum InteractionAddressType: Hashable {
        case user(_ address: String)
        case contract(_ address: String)
        case multiple(_ addresses: [String])
        // Temp solution for Visa
        case custom(message: String)
        case staking(validator: String?)
    }

    enum TransactionType: Hashable {
        case transfer
        case swap
        case stake
        case approve
        case unstake
        case vote
        case withdraw
        case claimRewards
        case unknownOperation
        case operation(name: String)
    }

    enum Status {
        case inProgress
        case failed
        case confirmed
    }
}
