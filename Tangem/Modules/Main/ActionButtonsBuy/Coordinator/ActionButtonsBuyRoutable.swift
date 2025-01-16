//
//  ActionButtonsBuyRoutable.swift
//  TangemApp
//
//  Created by GuitarKitty on 06.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol ActionButtonsBuyRoutable: AnyObject {
    func openOnramp(walletModel: WalletModel)
    func openBuyCrypto(at url: URL)
    func openAddToPortfolio(_ infoModel: HotCryptoAddToPortfolioModel)
    func closeAddToPortfolio()
    func dismiss()
}
