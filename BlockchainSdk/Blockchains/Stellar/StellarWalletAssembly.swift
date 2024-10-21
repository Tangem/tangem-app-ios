//
//  StellarWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import stellarsdk

struct StellarWalletAssembly: WalletManagerAssembly {
    
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        return StellarWalletManager(wallet: input.wallet).then {
            let blockchain = input.blockchain
            let providers: [StellarNetworkProvider] = APIResolver(blockchain: blockchain, config: input.blockchainSdkConfig).resolveProviders(apiInfos: input.apiInfo) { nodeInfo, _ in
                StellarNetworkProvider(
                    isTestnet: blockchain.isTestnet,
                    stellarSdk: .init(withHorizonUrl: nodeInfo.link)
                )
            }

            $0.txBuilder = StellarTransactionBuilder(walletPublicKey: input.wallet.publicKey.blockchainKey, isTestnet: input.blockchain.isTestnet)
            $0.networkService = StellarNetworkService(providers: providers)
        }
    }
    
}
