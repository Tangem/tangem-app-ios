//
//  ActionButtonsTokenSelectorItem.swift
//  TangemApp
//
//  Created by GuitarKitty on 05.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct ActionButtonsTokenSelectorItem: Identifiable, Equatable {
    let id: Int
    let tokenIconInfo: TokenIconInfo
    let name: String
    let symbol: String
    let balance: String
    let fiatBalance: String
    let isDisabled: Bool
    let isLoading: Bool
    let walletModel: WalletModel
}
