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
        canSend: Bool,
        exchangeUtility: ExchangeCryptoUtility
    ) -> [TokenActionType] {
        let canBuy = exchangeUtility.buyAvailable
        let canSell = exchangeUtility.sellAvailable

        var availableActions: [TokenActionType] = [.copyAddress]
        if canExchange, canBuy {
            availableActions.append(.buy)
        }

        if canSend {
            availableActions.append(.send)
        }

        availableActions.append(.receive)

        if canExchange, canSell {
            availableActions.append(.sell)
        }

        availableActions.append(.hide)

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
