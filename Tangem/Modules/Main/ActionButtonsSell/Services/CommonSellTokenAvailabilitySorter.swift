//
//  CommonSellTokenAvailabilitySorter.swift
//  TangemApp
//
//  Created by GuitarKitty on 12.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

struct CommonSellTokenAvailabilitySorter: TokenAvailabilitySorter {
    @Injected(\.exchangeService) private var exchangeService: ExchangeService

    func sortModels(walletModels: [WalletModel]) async -> (availableModels: [WalletModel], unavailableModels: [WalletModel]) {
        walletModels.reduce(
            into: (availableModels: [WalletModel](), unavailableModels: [WalletModel]())
        ) { result, walletModel in

            guard
                exchangeService.canSell(
                    walletModel.tokenItem.currencySymbol,
                    amountType: walletModel.amountType,
                    blockchain: walletModel.blockchainNetwork.blockchain
                ),
                !walletModel.state.isBlockchainUnreachable
            else {
                result.unavailableModels.append(walletModel)
                return
            }

            result.availableModels.append(walletModel)
        }
    }
}
