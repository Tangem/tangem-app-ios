//
//  RadiantWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 05.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct RadiantWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let socketManagers: [ElectrumWebSocketProvider] = APIResolver(blockchain: input.blockchain, config: input.blockchainSdkConfig)
            .resolveProviders(apiInfos: input.apiInfo, factory: { nodeInfo, _ in
                ElectrumWebSocketProvider(url: nodeInfo.url)
            })
        
        let publicKey = try Secp256k1Key(with: input.wallet.publicKey.blockchainKey).compress()
        
        let transactionBuilder = try RadiantTransactionBuilder(
            walletPublicKey: publicKey,
            decimalValue: input.blockchain.decimalValue
        )
        
        return try RadiantWalletManager(
            wallet: input.wallet,
            transactionBuilder: transactionBuilder,
            networkService: RadiantNetworkService(
                electrumProvider: .init(providers: socketManagers)
            )
        )
    }
}
