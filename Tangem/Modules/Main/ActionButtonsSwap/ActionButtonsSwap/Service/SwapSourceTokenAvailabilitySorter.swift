//
//  SwapSourceTokenAvailabilitySorter.swift
//  TangemApp
//
//  Created by Viacheslav E. on 22.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

struct SwapSourceTokenAvailabilitySorter: TokenAvailabilitySorter {
    @Injected(\.expressAvailabilityProvider)
    private var expressAvailabilityProvider: ExpressAvailabilityProvider

    func sortModels(walletModels: [WalletModel]) -> (availableModels: [WalletModel], unavailableModels: [WalletModel]) {
        walletModels.reduce(
            into: (availableModels: [WalletModel](), unavailableModels: [WalletModel]())
        ) { result, walletModel in

            if expressAvailabilityProvider.canSwap(tokenItem: walletModel.tokenItem), !walletModel.isCustom, !walletModel.state.isBlockchainUnreachable {
                result.availableModels.append(walletModel)
            } else {
                result.unavailableModels.append(walletModel)
            }
        }
    }
}
