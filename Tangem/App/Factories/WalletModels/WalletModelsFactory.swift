//
//  WalletModelsFactory.swift
//  Tangem
//
//  Created by Alexander Osokin on 19.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol WalletModelsFactory {
    func makeWalletModels(from walletManager: WalletManager) -> [WalletModel]
    func makeWalletModels(for types: [Amount.AmountType], walletManager: WalletManager) -> [WalletModel]
}
