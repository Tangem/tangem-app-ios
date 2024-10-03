//
//  SendSuggestedDestinationViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 09.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - View model

class SendSuggestedDestinationViewModel {
    private(set) var cellViewModels: [CellModel] = []

    private let tapAction: (SendSuggestedDestination) -> Void

    init(
        wallets: [SendSuggestedDestinationWallet],
        recentTransactions: [SendSuggestedDestinationTransactionRecord],
        tapAction: @escaping (SendSuggestedDestination) -> Void
    ) {
        self.tapAction = tapAction

        var cellViewModels: [CellModel] = []

        if !wallets.isEmpty {
            cellViewModels.append(CellModel(type: .header(title: Localization.sendRecipientWalletsTitle), tapAction: nil))
            cellViewModels.append(
                contentsOf: wallets.map { [weak self] wallet in
                    CellModel(
                        type: .wallet(wallet: wallet, addressIconViewModel: AddressIconViewModel(address: wallet.address)),
                        tapAction: {
                            self?.tapAction(SendSuggestedDestination(address: wallet.address, additionalField: nil, type: .otherWallet))
                        }
                    )
                }
            )
        }

        if !recentTransactions.isEmpty {
            cellViewModels.append(CellModel(type: .header(title: Localization.sendRecentTransactions), tapAction: nil))
            cellViewModels.append(
                contentsOf: recentTransactions.map { [weak self] record in
                    CellModel(
                        type: .recentTransaction(record: record, addressIconViewModel: AddressIconViewModel(address: record.address)),
                        tapAction: {
                            self?.tapAction(SendSuggestedDestination(address: record.address, additionalField: record.additionalField, type: .recentAddress))
                        }
                    )
                }
            )
        }

        self.cellViewModels = cellViewModels
    }
}

// MARK: - Cell model

extension SendSuggestedDestinationViewModel {
    struct CellModel: Identifiable {
        let id = UUID()

        let type: `Type`
        let tapAction: (() -> Void)?
    }
}

// MARK: - Helper types

extension SendSuggestedDestinationViewModel.CellModel {
    enum `Type` {
        case header(title: String)
        case wallet(wallet: SendSuggestedDestinationWallet, addressIconViewModel: AddressIconViewModel)
        case recentTransaction(record: SendSuggestedDestinationTransactionRecord, addressIconViewModel: AddressIconViewModel)
    }
}

struct SendSuggestedDestination {
    let address: String
    let additionalField: String?
    let type: DestinationType
}

extension SendSuggestedDestination {
    enum DestinationType {
        case otherWallet
        case recentAddress
    }
}

struct SendSuggestedDestinationWallet {
    let name: String
    let address: String
}

struct SendSuggestedDestinationTransactionRecord {
    let address: String
    let additionalField: String?
    let isOutgoing: Bool
    let date: Date
    let amountFormatted: String
    let dateFormatted: String
}

extension SendSuggestedDestinationTransactionRecord {
    func description(_ amount: String) -> String {
        "\(amount), \(dateFormatted)"
    }
}
