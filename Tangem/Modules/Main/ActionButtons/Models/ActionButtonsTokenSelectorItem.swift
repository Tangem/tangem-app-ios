//
//  ActionButtonsTokenSelectorItem.swift
//  TangemApp
//
//  Created by GuitarKitty on 05.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

struct ActionButtonsTokenSelectorItem: Identifiable, Equatable {
    let id: Int
    let tokenIconInfo: TokenIconInfo
    let name: String
    let symbol: String
    let balance: String
    let fiatBalance: String
    let isDisabled: Bool
    let walletModel: WalletModel
}
