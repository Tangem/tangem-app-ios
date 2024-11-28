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
}

// MARK: - TokenAvailabilitySorter

extension CommonBuyTokenAvailabilitySorter: TokenAvailabilitySorter {
    func sortModels(walletModels: [WalletModel]) async -> (availableModels: [WalletModel], unavailableModels: [WalletModel]) {
        walletModels.reduce(
            into: (availableModels: [WalletModel](), unavailableModels: [WalletModel]())
        ) { result, walletModel in
            if expressAvailabilityProvider.canOnramp(tokenItem: walletModel.tokenItem) {
                result.availableModels.append(walletModel)
            } else {
                result.unavailableModels.append(walletModel)
            }
        }
    }
}
