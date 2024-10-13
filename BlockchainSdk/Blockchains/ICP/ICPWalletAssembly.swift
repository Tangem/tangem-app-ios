//
//  ICPWalletAssembly.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 12.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import IcpKit
import TangemSdk

struct ICPWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> any WalletManager {
        let blockchain = input.blockchain
        let config = input.blockchainSdkConfig
        
        let providers: [ICPNetworkProvider] = APIResolver(blockchain: blockchain, config: config)
            .resolveProviders(apiInfos: input.apiInfo) { nodeInfo, _ in
                ICPNetworkProvider(
                    node: nodeInfo,
                    networkConfig: input.networkConfig,
                    responseParser: ICPResponseParser()
                )
            }
        
        let transactionBuilder = ICPTransactionBuilder(
            decimalValue: input.wallet.blockchain.decimalValue,
            publicKey: input.wallet.publicKey.blockchainKey,
            nonce: try CryptoUtils.icpNonce()
       )
        
        return ICPWalletManager(
            wallet: input.wallet,
            transactionBuilder: transactionBuilder,
            networkService: ICPNetworkService(
                providers: providers,
                blockchain: input.blockchain
            )
        )
    }
}
