//
//  AnyWalletManagerFactory.swift
//  Tangem
//
//  Created by Alexander Osokin on 27.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol AnyWalletManagerFactory {
    func makeWalletManager(for token: StorageEntry, keys: [CardDTO.Wallet]) throws -> WalletManager
}

enum AnyWalletManagerFactoryError: Error {
    case entryHasNotDerivationPath
    case noDerivation
    case walletWithBlockchainCurveNotFound
}
