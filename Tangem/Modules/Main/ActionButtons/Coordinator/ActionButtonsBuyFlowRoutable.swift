//
//  ActionButtonsBuyFlowRoutable.swift
//  TangemApp
//
//  Created by GuitarKitty on 06.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

protocol ActionButtonsBuyFlowRoutable: AnyObject {
    func openBuy(userWalletModel: some UserWalletModel)
}
