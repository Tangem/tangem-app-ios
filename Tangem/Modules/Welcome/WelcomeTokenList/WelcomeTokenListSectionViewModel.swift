//
//  WelcomeTokenListSectionViewModel.swift
//  Tangem
//
//  Created by skibinalexander on 19.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

class WelcomeTokenListSectionViewModel: Identifiable, ObservableObject {
    let id: UUID = .init()
    let imageURL: URL?
    let name: String
    let symbol: String
    let items: [WelcomeTokenListItemViewModel]

    init(imageURL: URL?, name: String, symbol: String, items: [WelcomeTokenListItemViewModel]) {
        self.imageURL = imageURL
        self.name = name
        self.symbol = symbol
        self.items = items
    }

    init(with model: CoinModel, items: [WelcomeTokenListItemViewModel]) {
        name = model.name
        symbol = model.symbol
        imageURL = TokenIconURLBuilder().iconURL(id: model.id, size: .large)
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

extension WelcomeTokenListSectionViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: WelcomeTokenListSectionViewModel, rhs: WelcomeTokenListSectionViewModel) -> Bool {
        lhs.id == rhs.id
    }
}
