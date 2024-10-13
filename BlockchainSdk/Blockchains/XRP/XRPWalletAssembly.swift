//
//  XRPWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct XRPWalletAssembly: WalletManagerAssembly {
    
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        return try XRPWalletManager(wallet: input.wallet).then {
            $0.txBuilder = try XRPTransactionBuilder(walletPublicKey: input.wallet.publicKey.blockchainKey, curve: input.blockchain.curve)

            let blockchain = input.blockchain
            let config = input.blockchainSdkConfig
            let providers: [XRPNetworkProvider] = APIResolver(blockchain: blockchain, config: config)
                .resolveProviders(apiInfos: input.apiInfo) { nodeInfo, _ in
                    XRPNetworkProvider(node: nodeInfo, configuration: input.networkConfig)
                }

            $0.networkService = XRPNetworkService(providers: providers)
        }
    }
    
}
