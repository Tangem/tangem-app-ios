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
    let id: String
    private let interactionAddress: InteractionAddressType
    private let timeFormatted: String?
    private let amount: String
    private let isOutgoing: Bool
    private let transactionType: TransactionType
    private let status: Status

    init(
        id: String,
        interactionAddress: InteractionAddressType,
        timeFormatted: String?,
        amount: String,
        isOutgoing: Bool,
        transactionType: TransactionViewModel.TransactionType,
        status: TransactionViewModel.Status
    ) {
        self.id = id
        self.interactionAddress = interactionAddress
        self.timeFormatted = timeFormatted
        self.amount = amount
        self.isOutgoing = isOutgoing
        self.transactionType = transactionType
        self.status = status
    }

    var inProgress: Bool {
        status == .inProgress
    }

    var subtitleText: String {
        switch status {
        case .confirmed, .failed:
            return timeFormatted ?? "-"
        case .inProgress:
            return Localization.transactionHistoryTxInProgress
        }
    }

    var formattedAmount: String? {
        switch transactionType {
        case .approval:
            return nil
        case .transfer, .swap, .custom:
            return amount
        }
    }

    var amountTextColor: Color {
        isOutgoing ? Colors.Text.tertiary : Colors.Text.accent
    }

    var localizeDestination: String {
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
            return Localization.transactionHistoryMultipleAddresses
        }
    }

    var name: String {
        switch transactionType {
        case .transfer: return Localization.commonTransfer
        case .swap: return Localization.commonSwap
        case .approval: return Localization.commonApproval
        case .custom(name: let name): return name.capitalized
        }
    }

    var icon: Image {
        switch transactionType {
        case .transfer:
            return isOutgoing ? Assets.arrowUpMini.image : Assets.arrowDownMini.image
        case .swap:
            return Assets.exchangeMini.image
        case .approval:
            return Assets.approve.image
        case .custom:
            return Assets.exchangeMini.image
        }
    }

    var iconColor: Color {
        switch status {
        case .inProgress:
            return Colors.Icon.attention
        case .confirmed, .failed:
            return Colors.Icon.informative
        }
    }

    var iconBackgroundColor: Color {
        switch status {
        case .inProgress: return iconColor.opacity(0.1)
        case .confirmed, .failed: return Colors.Background.secondary
        }
    }

    var textColor: Color {
        switch status {
        case .inProgress:
            return Colors.Text.attention
        case .confirmed, .failed:
            return Colors.Text.tertiary
        }
    }
}

extension TransactionViewModel {
    enum InteractionAddressType: Hashable {
        case user(_ address: String)
        case contract(_ address: String)
        case multiple(_ addresses: [String])
    }

    enum TransactionType: Hashable {
        case transfer
        case swap
        case approval
        case custom(name: String)
    }

    enum Status {
        case inProgress
        case failed
        case confirmed
    }
}
