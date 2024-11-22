//
//  SwapToTokenAvailabilitySorter.swift
//  TangemApp
//
//  Created by Viacheslav E. on 22.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemExpress

struct SwapSourceTokenAvailabilitySorter: TokenAvailabilitySorter {
    @Injected(\.expressAvailabilityProvider)
    private var expressAvailabilityProvider: ExpressAvailabilityProvider

    let sourceTokenWalletModel: WalletModel
    let expressRepository: ExpressRepository

    init(
        sourceTokenWalletModel: WalletModel,
        expressRepository: ExpressRepository
    ) {
        self.sourceTokenWalletModel = sourceTokenWalletModel
        self.expressRepository = expressRepository
    }

    func sortModels(walletModels: [WalletModel]) async -> (availableModels: [WalletModel], unavailableModels: [WalletModel]) {
        let availablePairs = await expressRepository.getPairs(from: sourceTokenWalletModel)

        let result = walletModels.filter { $0 != sourceTokenWalletModel }.reduce(
            into: (availableModels: [WalletModel](), unavailableModels: [WalletModel]())
        ) { result, walletModel in
            if availablePairs.map(\.destination).contains(walletModel.expressCurrency) {
                result.availableModels.append(walletModel)
            } else {
                result.unavailableModels.append(walletModel)
            }
        }

        return result
    }
}
