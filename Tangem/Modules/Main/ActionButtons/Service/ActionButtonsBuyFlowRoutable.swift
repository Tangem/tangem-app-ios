//
//  ActionButtonsBuyFlowRoutable.swift
//  TangemApp
//
//  Created by GuitarKitty on 06.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine

protocol ActionButtonsBuyFlowRoutable: AnyObject {
    func openBuy(
        userWalletModel: some UserWalletModel,
        hotCryptoItemsSubject: CurrentValueSubject<[HotCryptoDataItem], Never>
    )
    func openP2PTutorial()
    func openBankWarning(confirmCallback: @escaping () -> Void, declineCallback: @escaping () -> Void)
}
