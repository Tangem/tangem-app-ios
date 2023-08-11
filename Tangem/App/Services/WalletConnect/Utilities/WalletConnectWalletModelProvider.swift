//
//  CommonWalletConnectWalletModelProvider.swift
//  Tangem
//
//  Created by Andrew Son on 21/07/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol WalletConnectWalletModelProvider {
    // This info is based on information from WC and they didn't know anything about derivation
    // So we need to compare blockchain and address to simulate comparision of derivation path
    // Information about address is encoded in request params and info about blockchain - request chainId
    func getModel(with address: String, blockchainId: String) throws -> WalletModel
}

struct CommonWalletConnectWalletModelProvider: WalletConnectWalletModelProvider {
    private let walletModelsManager: WalletModelsManager

    init(walletModelsManager: WalletModelsManager) {
        self.walletModelsManager = walletModelsManager
    }

    func getModel(with address: String, blockchainId: String) throws -> WalletModel {
        guard
            let model = walletModelsManager.walletModels.first(where: {
                $0.wallet.blockchain.coinId == blockchainId && $0.wallet.address.caseInsensitiveCompare(address) == .orderedSame
            })
        else {
            throw WalletConnectV2Error.walletModelNotFound(blockchainId)
        }

        return model
    }
}
