//
//  CommonWalletModelsFactory.swift
//  Tangem
//
//  Created by Alexander Osokin on 19.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct CommonWalletModelsFactory {
    private let derivationStyle: DerivationStyle?

    init(derivationStyle: DerivationStyle?) {
        self.derivationStyle = derivationStyle
    }

    private func isDerivationDefault(blockchain: Blockchain, derivationPath: DerivationPath?) -> Bool {
        guard let derivationStyle else {
            return true
        }

        let defaultDerivation = blockchain.derivationPaths(for: derivationStyle)[.default]
        return derivationPath == defaultDerivation
    }
}

extension CommonWalletModelsFactory: WalletModelsFactory {
    func makeWalletModels(from walletManager: WalletManager) -> [WalletModel] {
        let currentBlockchain = walletManager.wallet.blockchain
        let currentDerivation = walletManager.wallet.publicKey.derivationPath
        let isMainCoinCustom = !isDerivationDefault(blockchain: currentBlockchain, derivationPath: currentDerivation)

        let mainCoinModel = WalletModel(walletManager: walletManager, amountType: .coin, isCustom: isMainCoinCustom)

        let tokenModels = walletManager.cardTokens.map { token in
            let amountType: Amount.AmountType = .token(value: token)
            let isTokenCustom = isMainCoinCustom || token.id == nil
            let tokenModel = WalletModel(walletManager: walletManager, amountType: amountType, isCustom: isTokenCustom)
            return tokenModel
        }

        return [mainCoinModel] + tokenModels
    }
}
