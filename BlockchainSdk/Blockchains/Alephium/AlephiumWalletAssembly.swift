//
//  AlephiumWalletAssembly.swift
//  BlockchainSdk
//
//  Created by Alexander Skibin on 17.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct AlephiumWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        AlephiumWalletManager(
            wallet: input.wallet,
            networkService: AlephiumNetworkService(),
            transactionBuilder: AlephiumTransactionBuilder()
        )
    }
}
