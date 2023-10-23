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
    var id: String { hash }
    let hash: String
    private let interactionAddress: InteractionAddressType
    private let timeFormatted: String?
    private let amount: String
    private let isOutgoing: Bool
    private let transactionType: TransactionType
    private let status: Status

    init(
        hash: String,
        interactionAddress: InteractionAddressType,
        timeFormatted: String?,
        amount: String,
        isOutgoing: Bool,
        transactionType: TransactionViewModel.TransactionType,
        status: TransactionViewModel.Status
    ) {
        self.hash = hash
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
        return timeFormatted ?? "-"
    }

    var formattedAmount: String? {
        switch transactionType {
        case .approval:
            return nil
        case .transfer, .swap, .operation:
            return amount
        }
    }

    var amountTextColor: Color {
        if status == .failed {
            return Colors.Text.warning
        }

        return isOutgoing ? Colors.Text.tertiary : Colors.Text.accent
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
            if isOutgoing {
                return Localization.transactionHistoryTransactionToAddress(
                    Localization.transactionHistoryMultipleAddresses
                )
            } else {
                return Localization.transactionHistoryTransactionFromAddress(
                    Localization.transactionHistoryMultipleAddresses
                )
            }
        }
    }

    var name: String {
        switch transactionType {
        case .transfer: return Localization.commonTransfer
        case .swap: return Localization.commonSwap
        case .approval: return Localization.commonApproval
        case .operation(name: let name): return name
        }
    }

    var icon: Image {
        if status == .failed {
            return Assets.cross.image
        }

        switch transactionType {
        case .transfer:
            return isOutgoing ? Assets.arrowUpMini.image : Assets.arrowDownMini.image
        case .swap:
            return Assets.exchangeMini.image
        case .approval:
            return Assets.approve.image
        case .operation:
            // TODO: Updated in https://tangem.atlassian.net/browse/IOS-4836
            return Assets.exchangeMini.image
        }
    }

    var iconColor: Color {
        switch status {
        case .inProgress:
            return Colors.Icon.attention
        case .confirmed:
            return Colors.Icon.informative
        case .failed:
            return Colors.Icon.warning
        }
    }

    var iconBackgroundColor: Color {
        switch status {
        case .inProgress: return Colors.Icon.attention.opacity(0.1)
        case .confirmed: return Colors.Background.secondary
        case .failed: return Colors.Icon.warning.opacity(0.1)
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
        case operation(name: String)
    }

    enum Status {
        case inProgress
        case failed
        case confirmed
    }
}
