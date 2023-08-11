//
//  LegacyCoinViewModel.swift
//  Tangem
//
//  Created by Alexander Osokin on 18.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class LegacyCoinViewModel: Identifiable, ObservableObject {
    let id: UUID = .init()
    let imageURL: URL?
    let name: String
    let symbol: String
    let items: [LegacyCoinItemViewModel]

    init(imageURL: URL?, name: String, symbol: String, items: [LegacyCoinItemViewModel]) {
        self.imageURL = imageURL
        self.name = name
        self.symbol = symbol
        self.items = items
    }

    init(with model: CoinModel, items: [LegacyCoinItemViewModel]) {
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

extension LegacyCoinViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: LegacyCoinViewModel, rhs: LegacyCoinViewModel) -> Bool {
        lhs.id == rhs.id
    }
}
