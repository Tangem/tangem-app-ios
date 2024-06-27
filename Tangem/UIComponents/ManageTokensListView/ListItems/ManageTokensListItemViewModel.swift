//
//  ManageTokensListItemViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 21/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class ManageTokensListItemViewModel: ObservableObject, Identifiable {
    let id: UUID = .init()
    let imageURL: URL?
    let name: String
    let symbol: String
    let items: [ManageTokensItemNetworkSelectorViewModel]

    init(imageURL: URL?, name: String, symbol: String, items: [ManageTokensItemNetworkSelectorViewModel]) {
        self.imageURL = imageURL
        self.name = name
        self.symbol = symbol
        self.items = items
    }

    init(with model: CoinModel, items: [ManageTokensItemNetworkSelectorViewModel]) {
        name = model.name
        symbol = model.symbol
        imageURL = IconURLBuilder().tokenIconURL(id: model.id, size: .large)
        self.items = items
    }

    func hasContractAddress(_ contractAddress: String) -> Bool {
        items.contains { item in
            guard let tokenContractAddress = item.tokenItem.contractAddress else {
                return false
            }

            return tokenContractAddress.caseInsensitiveCompare(contractAddress) == .orderedSame
        }
    }
}

extension ManageTokensListItemViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ManageTokensListItemViewModel, rhs: ManageTokensListItemViewModel) -> Bool {
        lhs.id == rhs.id
    }
}
