//
//  SwapDestinationTokenAvailabilitySorter.swift
//  TangemApp
//
//  Created by Viacheslav E. on 22.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemExpress

struct SwapDestinationTokenAvailabilitySorter {
    // MARK: - Dependencies

    @Injected(\.expressAvailabilityProvider)
    private var expressAvailabilityProvider: ExpressAvailabilityProvider

    // MARK: - Private property

    private let sourceTokenWalletModel: WalletModel
    private let expressRepository: ExpressRepository

    init(
        sourceTokenWalletModel: WalletModel,
        expressRepository: ExpressRepository
    ) {
        self.sourceTokenWalletModel = sourceTokenWalletModel
        self.expressRepository = expressRepository
    }
}

// MARK: - TokenAvailabilitySorter

extension SwapDestinationTokenAvailabilitySorter: TokenAvailabilitySorter {
    func sortModels(walletModels: [WalletModel]) async -> (availableModels: [WalletModel], unavailableModels: [WalletModel]) {
        let availablePairs = await expressRepository.getPairs(from: sourceTokenWalletModel)

        let result = walletModels.filter { $0 != sourceTokenWalletModel }.reduce(
            into: (availableModels: [WalletModel](), unavailableModels: [WalletModel]())
        ) { result, walletModel in
            if availablePairs.map(\.destination).contains(walletModel.expressCurrency), !walletModel.isCustom {
                result.availableModels.append(walletModel)
            } else {
                result.unavailableModels.append(walletModel)
            }
        }

        return result
    }
}
