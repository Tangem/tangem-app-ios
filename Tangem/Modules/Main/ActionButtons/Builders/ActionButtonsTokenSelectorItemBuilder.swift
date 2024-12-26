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
        let balanceBuilder = LoadableTokenBalanceViewStateBuilder()
        let balance = walletModel.combineBalanceProvider.formattedBalanceType
        let fiatBalance = walletModel.combineFiatBalanceProvider.formattedBalanceType

        // TODO. Better to use logic
        // from `DefaultTokenItemInfoProvider` or DefaultTokenItemInfoProvider
        // to support balance state changes loading / loaded / cached
        return ActionButtonsTokenSelectorItem(
            id: walletModel.id,
            tokenIconInfo: tokenIconInfo,
            name: walletModel.tokenItem.name,
            symbol: walletModel.tokenItem.currencySymbol,
            balance: balanceBuilder.build(type: balance),
            fiatBalance: balanceBuilder.build(type: fiatBalance, icon: .leading),
            isDisabled: isDisabled,
            walletModel: walletModel
        )
    }
}
