//
//  TokenActionListBuilder.swift
//  Tangem
//
//  Created by Andrew Son on 15/06/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct TokenActionListBuilder {
    func buildActionsForButtonsList(canShowSwap: Bool) -> [TokenActionType] {
        var actions: [TokenActionType] = [.buy, .send, .receive, .sell]
        if canShowSwap {
            actions.append(.exchange)
        }

        return actions
    }

    func buildTokenContextActions(
        canExchange: Bool,
        exchangeUtility: ExchangeCryptoUtility,
        canHide: Bool
    ) -> [TokenActionType] {
        let canBuy = exchangeUtility.buyAvailable
        let canSell = exchangeUtility.sellAvailable

        var availableActions: [TokenActionType] = [.copyAddress, .send, .receive]

        if canExchange {
            if canBuy {
                availableActions.insert(.buy, at: 0)
            }
            if canSell {
                availableActions.append(.sell)
            }
        }

        if canHide {
            availableActions.append(.hide)
        }

        return availableActions
    }

    func buildActionsForLockedSingleWallet() -> [TokenActionType] {
        [
            .buy,
            .send,
            .receive,
            .sell,
        ]
    }
}
