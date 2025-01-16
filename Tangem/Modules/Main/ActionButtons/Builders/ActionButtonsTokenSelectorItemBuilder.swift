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
        let infoProvider = DefaultTokenItemInfoProvider(walletModel: walletModel)

        return ActionButtonsTokenSelectorItem(
            id: walletModel.id,
            isDisabled: isDisabled,
            tokenIconInfo: tokenIconInfo,
            infoProvider: infoProvider,
            walletModel: walletModel
        )
    }
}
