//
//  PendingTransaction.swift
//  Tangem
//
//  Created by Andrew Son on 11/06/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import SwiftUI

struct LegacyTransactionRecord: Hashable, Identifiable {
    var id: Int { hashValue }

    let amountType: Amount.AmountType
    let destination: String
    let timeFormatted: String
    var date: Date?
    let transferAmount: String
    let transactionType: TransactionType
    let status: Status
}

extension LegacyTransactionRecord {
    enum TransactionType: Hashable {
        case receive
        case send
        case swap(type: SwapType)
        case approval

        var amountPrefix: String {
            switch self {
            case .receive: return "+"
            case .send, .approval: return "-"
            case .swap(let type): return type.amountPrefix
            }
        }

        var name: String {
            switch self {
            case .receive, .send: return Localization.commonTransfer
            case .swap: return Localization.commonSwap
            case .approval: return Localization.commonApproval
            }
        }

        var amountTextColor: Color {
            switch self {
            case .receive: return Colors.Text.accent
            case .swap(let swapType):
                switch swapType {
                case .buy: return Colors.Text.accent
                case .sell: return Colors.Text.tertiary
                }
            case .send, .approval: return Colors.Text.tertiary
            }
        }

        func localizeDestination(for address: String) -> String {
            switch self {
            case .receive: return Localization.transactionHistoryTransactionFromAddress(address)
            case .send: return Localization.transactionHistoryTransactionToAddress(address)
            case .swap, .approval: return Localization.transactionHistoryContractAddress(address)
            }
        }
    }

    enum Status {
        case inProgress
        case confirmed

        init(_ blockchainSdkStatus: TransactionStatus) {
            switch blockchainSdkStatus {
            case .confirmed:
                self = .confirmed
            case .unconfirmed:
                self = .inProgress
            }
        }

        var iconColor: Color {
            switch self {
            case .inProgress:
                return Colors.Icon.attention
            case .confirmed:
                return Colors.Icon.informative
            }
        }

        var iconBackgroundColor: Color {
            switch self {
            case .inProgress: return iconColor.opacity(0.1)
            case .confirmed: return Colors.Background.secondary
            }
        }

        var textColor: Color {
            switch self {
            case .inProgress:
                return Colors.Text.attention
            case .confirmed:
                return Colors.Text.tertiary
            }
        }
    }

    enum SwapType: Hashable {
        case buy
        case sell

        var amountPrefix: String {
            switch self {
            case .buy: return "+"
            case .sell: return "-"
            }
        }
    }
}
