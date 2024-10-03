//
//  VisaWalletManagerFactory.swift
//  Tangem
//
//  Created by Andrew Son on 14/12/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk
import TangemVisa

struct VisaWalletManagerFactory: AnyWalletManagerFactory {
    func makeWalletManager(for token: StorageEntry, keys: [CardDTO.Wallet], apiList: APIList) throws -> WalletManager {
        let blockchain = VisaUtilities().visaBlockchain

        guard let walletPublicKey = keys.first(where: { $0.curve == blockchain.curve })?.publicKey else {
            throw CommonError.noData
        }

        let factory = WalletManagerFactoryProvider(apiList: apiList).factory
        let publicKey = Wallet.PublicKey(seedKey: walletPublicKey, derivationType: .none)
        let walletManager = try factory.makeWalletManager(blockchain: blockchain, publicKey: publicKey)

        return walletManager
    }
}
