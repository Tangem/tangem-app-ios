//
//  MarketsPortfolioContainerRoutable.swift
//  Tangem
//
//  Created by skibinalexander on 14.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol MarketsPortfolioContainerRoutable: AnyObject {
    func openReceive(walletModel: WalletModel)
    func openBuyCryptoIfPossible(for walletModel: WalletModel, with userWalletModel: UserWalletModel)
    func openExchange(for walletModel: WalletModel, with userWalletModel: UserWalletModel)
    func openOnramp(for walletModel: WalletModel, with userWalletModel: UserWalletModel)
}
