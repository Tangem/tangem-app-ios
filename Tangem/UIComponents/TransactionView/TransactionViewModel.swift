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
        case .approve:
            return nil
        case .transfer, .swap, .operation, .unknownOperation:
            return amount
        }
    }

    var localizeDestination: String {
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
        }
    }

    var name: String {
        switch transactionType {
        case .transfer: return Localization.commonTransfer
        case .swap: return Localization.commonSwap
        case .approve: return Localization.commonApproval
        case .unknownOperation: return Localization.transactionHistoryOperation
        case .operation(name: let name): return name
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
}

extension TransactionViewModel {
    enum InteractionAddressType: Hashable {
        case user(_ address: String)
        case contract(_ address: String)
        case multiple(_ addresses: [String])
        // Temp solution for Visa
        case custom(message: String)
    }

    enum TransactionType: Hashable {
        case transfer
        case swap
        case approve
        case unknownOperation
        case operation(name: String)
    }

    enum Status {
        case inProgress
        case failed
        case confirmed
    }
}
