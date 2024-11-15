//
//  ActionButtonsSendToSellModel.swift
//  TangemApp
//
//  Created by GuitarKitty on 15.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct ActionButtonsSendToSellModel {
    let amountToSend: Amount
    let destination: String
    let tag: String?
    let walletModel: WalletModel
}
