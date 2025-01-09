//
//  ActionButtonsTokenSelectorItemBuilder.swift
//  TangemApp
//
//  Created by GuitarKitty on 01.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

struct ActionButtonsTokenSelectorItemBuilder: TokenSelectorItemBuilder {
    func map(from walletModel: WalletModel, isDisabled: Bool) -> ActionButtonsTokenSelectorItem {
        let tokenIconInfo = TokenIconInfoBuilder().build(from: walletModel.tokenItem, isCustom: walletModel.isCustom)

        return ActionButtonsTokenSelectorItem(
            id: walletModel.id,
            tokenIconInfo: tokenIconInfo,
            name: walletModel.tokenItem.name,
            symbol: walletModel.tokenItem.currencySymbol,
            balance: walletModel.state.isLoading ? .loading() : .loaded(walletModel.balance),
            fiatBalance: walletModel.state.isLoading ? .loading() : .loaded(walletModel.fiatBalance),
            isDisabled: isDisabled,
            walletModel: walletModel
        )
    }
}
