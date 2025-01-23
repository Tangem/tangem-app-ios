//
//  ActionButtonsTokenSelectorItem.swift
//  TangemApp
//
//  Created by GuitarKitty on 05.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct ActionButtonsTokenSelectorItem: Identifiable, Equatable {
    let id: String
    let tokenIconInfo: TokenIconInfo
    let name: String
    let symbol: String
    let balance: LoadableTokenBalanceView.State
    let fiatBalance: LoadableTokenBalanceView.State
    let isDisabled: Bool
    let walletModel: WalletModel
}
