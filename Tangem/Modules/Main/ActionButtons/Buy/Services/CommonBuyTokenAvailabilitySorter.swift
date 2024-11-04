//
//  CommonBuyTokenAvailabilitySorter.swift
//  TangemApp
//
//  Created by GuitarKitty on 01.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

protocol BuyTokenAvailabilitySorter {
    func sortModels(walletModels: [WalletModel]) -> (availableModels: [WalletModel], unavailableModels: [WalletModel])
}

struct CommonBuyTokenAvailabilitySorter: BuyTokenAvailabilitySorter {
    @Injected(\.exchangeService) private var exchangeService: ExchangeService

    func sortModels(walletModels: [WalletModel]) -> (availableModels: [WalletModel], unavailableModels: [WalletModel]) {
        walletModels.reduce(into: (availableModels: [WalletModel](), unavailableModels: [WalletModel]())) { result, walletModel in
            if exchangeService.canBuy(
                walletModel.tokenItem.currencySymbol,
                amountType: walletModel.amountType,
                blockchain: walletModel.blockchainNetwork.blockchain
            ) {
                result.availableModels.append(walletModel)
            } else {
                result.unavailableModels.append(walletModel)
            }
        }
    }
}
