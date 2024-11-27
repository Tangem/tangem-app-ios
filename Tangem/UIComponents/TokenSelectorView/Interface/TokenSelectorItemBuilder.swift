//
//  TokenSelectorItemBuilder.swift
//  TangemApp
//
//  Created by GuitarKitty on 01.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

protocol TokenSelectorItemBuilder {
    associatedtype TokenModel

    func map(from walletModel: WalletModel, isDisabled: Bool) -> TokenModel
}
