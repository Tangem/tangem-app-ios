//
//  CommonActionButtonsBuyInteractor.swift
//  TangemApp
//
//  Created by GuitarKitty on 06.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class CommonActionButtonsBuyInteractor: ActionButtonsBuyInteractor {
    @Injected(\.exchangeService) private var exchangeService: ExchangeService

    func makeBuyUrl(from token: ActionButtonsTokenSelectorItem) -> URL? {
        let buyUrl = exchangeService.getBuyUrl(
            currencySymbol: token.symbol,
            amountType: token.amountType,
            blockchain: token.blockchain,
            walletAddress: token.defaultAddress
        )

        return buyUrl
    }
}
