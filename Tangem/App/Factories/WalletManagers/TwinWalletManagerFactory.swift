//
//  TwinWalletManagerFactory.swift
//  Tangem
//
//  Created by Alexander Osokin on 27.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct TwinWalletManagerFactory {
    private let pairPublicKey: Data

    init(pairPublicKey: Data) {
        self.pairPublicKey = pairPublicKey
    }
}

extension TwinWalletManagerFactory: AnyWalletManagerFactory {
    func makeWalletManager(for token: StorageEntry.V2.Entry, keys: [CardDTO.Wallet]) throws -> WalletManager {
        guard let walletPublicKey = keys.first?.publicKey else {
            throw CommonError.noData
        }

        let factory = WalletManagerFactoryProvider().factory
        let twinManager = try factory.makeTwinWalletManager(
            walletPublicKey: walletPublicKey,
            pairKey: pairPublicKey,
            isTestnet: AppEnvironment.current.isTestnet
        )

        return twinManager
    }
}
