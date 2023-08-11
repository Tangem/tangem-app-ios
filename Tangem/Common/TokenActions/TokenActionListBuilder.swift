//
//  TokenActionListBuilder.swift
//  Tangem
//
//  Created by Andrew Son on 15/06/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct TokenActionListBuilder {
    func buildActions(canExchange: Bool, exchangeUtility: ExchangeCryptoUtility) -> [TokenActionType] {
        let canBuy = exchangeUtility.buyAvailable
        let canSell = exchangeUtility.sellAvailable

        var availableActions: [TokenActionType] = [.send, .receive]

        if canExchange {
            if canBuy {
                availableActions.insert(.buy, at: 0)
            }
            if canSell {
                availableActions.append(.sell)
            }
        }

        return availableActions
    }
}
