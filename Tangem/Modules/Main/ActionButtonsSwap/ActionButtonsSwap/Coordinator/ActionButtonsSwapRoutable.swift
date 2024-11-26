//
//  ActionButtonsSwapRoutable.swift
//  TangemApp
//
//  Created by Viacheslav E. on 22.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

protocol ActionButtonsSwapRoutable: AnyObject {
    func openExpress(
        for sourceWalletModel: WalletModel,
        and destinationWalletModel: WalletModel,
        with userWalletModel: UserWalletModel
    )
    func dismiss()
}
