//
//  TokenIconViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 17.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct TokenIconViewModel: Hashable, Identifiable {
    let id: String?
    let name: String
    let style: Style

    var imageURL: URL? {
        guard let id else { return nil }

        return TokenIconURLBuilder()
            .iconURL(id: id, size: .large)
    }

    var blockchainIconName: String? {
        if case .token(let iconName) = style {
            return iconName
        }

        return nil
    }

    init(
        id: String?,
        name: String,
        style: TokenIconViewModel.Style
    ) {
        self.id = id
        self.name = name
        self.style = style
    }

    init(tokenItem: TokenItem) {
        switch tokenItem {
        case .blockchain(let blockchain):
            self.init(id: blockchain.coinId, name: blockchain.displayName, style: .blockchain)
        case .token(let token, let blockchain):
            self.init(id: token.id, name: token.name, style: .token(blockchain.iconNameFilled))
        }
    }

    init(with type: Amount.AmountType, blockchain: Blockchain) {
        switch type {
        case .coin, .reserve:
            self.init(id: blockchain.coinId, name: blockchain.displayName, style: .blockchain)
        case .token(let token):
            self.init(id: token.id, name: token.name, style: .token(blockchain.iconNameFilled))
        }
    }
}

extension TokenIconViewModel {
    enum Style: Hashable {
        case blockchain
        case token(_ blockchainIconName: String)
    }
}
