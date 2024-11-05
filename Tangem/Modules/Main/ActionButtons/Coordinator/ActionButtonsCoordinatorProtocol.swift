//
//  ActionButtonsRoutable.swift
//  Tangem
//
//  Created by GuitarKitty on 24.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol ActionButtonsRoutable {
    func openBuyCryptoIfPossible(userWalletModel: UserWalletModel)
    func openSwap()
    func openSell()
}
