//
//  TokenIconInfoBuilder.swift
//  Tangem
//
//  Created by Andrew Son on 03/05/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct TokenIconInfoBuilder {
    func build(for type: Amount.AmountType, in blockchain: Blockchain) -> TokenIconInfo {
        let id: String?
        let name: String
        var blockchainIconName: String?
        var imageURL: URL?

        switch type {
        case .coin, .reserve:
            id = blockchain.coinId
            name = blockchain.displayName
        case .token(let token):
            id = token.id
            name = token.name
            blockchainIconName = blockchain.iconNameFilled
        }

        if let id {
            imageURL = TokenIconURLBuilder()
                .iconURL(id: id, size: .large)
        }

        return .init(name: name, blockchainIconName: blockchainIconName, imageURL: imageURL)
    }

    func build(from tokenItem: TokenItem) -> TokenIconInfo {
        build(for: tokenItem.amountType, in: tokenItem.blockchain)
    }
}
