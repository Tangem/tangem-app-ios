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

    func getModels(with blockchainId: String) -> [WalletModel]

    func getModel(with blockchainId: String) -> WalletModel?
}

struct CommonWalletConnectWalletModelProvider: WalletConnectWalletModelProvider {
    private let walletModelsManager: WalletModelsManager

    private var mainWalletModels: [WalletModel] {
        walletModelsManager.walletModels.filter {
            $0.isMainToken
        }
    }

    init(walletModelsManager: WalletModelsManager) {
        self.walletModelsManager = walletModelsManager
    }

    func getModel(with address: String, blockchainId: String) throws -> WalletModel {
        guard
            let model = mainWalletModels.first(where: {
                $0.blockchainNetwork.blockchain.networkId == blockchainId
                    && $0.wallet.address.caseInsensitiveCompare(address) == .orderedSame
            })
        else {
            throw WalletConnectV2Error.walletModelNotFound(blockchainId)
        }

        return model
    }

    func getModels(with blockchainId: String) -> [WalletModel] {
        return mainWalletModels.filter { $0.blockchainNetwork.blockchain.networkId == blockchainId }
    }

    func getModel(with blockchainId: String) -> WalletModel? {
        mainWalletModels.first { $0.blockchainNetwork.blockchain.networkId == blockchainId }
    }
}
