//
//  CommonBuyTokenAvailabilitySorter.swift
//  TangemApp
//
//  Created by GuitarKitty on 01.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

struct CommonBuyTokenAvailabilitySorter {
    // MARK: - Dependencies

    @Injected(\.expressAvailabilityProvider)
    private var expressAvailabilityProvider: ExpressAvailabilityProvider

    @Injected(\.exchangeService)
    private var exchangeService: ExchangeService
}

// MARK: - TokenAvailabilitySorter

extension CommonBuyTokenAvailabilitySorter: TokenAvailabilitySorter {
    func sortModels(walletModels: [WalletModel]) async -> (availableModels: [WalletModel], unavailableModels: [WalletModel]) {
        walletModels.reduce(
            into: (availableModels: [WalletModel](), unavailableModels: [WalletModel]())
        ) { result, walletModel in
            if tokenAvailableToBuy(walletModel) {
                result.availableModels.append(walletModel)
            } else {
                result.unavailableModels.append(walletModel)
            }
        }
    }

    private func tokenAvailableToBuy(_ walletModel: WalletModel) -> Bool {
        if FeatureProvider.isAvailable(.onramp) {
            expressAvailabilityProvider.canOnramp(tokenItem: walletModel.tokenItem)
        } else {
            exchangeService.canBuy(
                walletModel.tokenItem.currencySymbol,
                amountType: walletModel.amountType,
                blockchain: walletModel.blockchainNetwork.blockchain
            )
        }
    }
}
