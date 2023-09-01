//
//  DemoWalletModelsFactory.swift
//  Tangem
//
//  Created by Alexander Osokin on 19.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct DemoWalletModelsFactory {
    private let factory: CommonWalletModelsFactory

    init(derivationStyle: DerivationStyle?) {
        factory = CommonWalletModelsFactory(derivationStyle: derivationStyle)
    }
}

extension DemoWalletModelsFactory: WalletModelsFactory {
    func makeWalletModels(from walletManager: WalletManager) -> [WalletModel] {
        return factory.makeWalletModels(from: walletManager)
    }

    func makeWalletModels(for types: [Amount.AmountType], walletManager: WalletManager) -> [WalletModel] {
        let models = factory.makeWalletModels(for: types, walletManager: walletManager)

        let demoUtil = DemoUtil()

        models.forEach {
            $0.demoBalance = demoUtil.getDemoBalance(for: $0.wallet.blockchain)
        }

        return models
    }
}
