//
//  RavencoinWalletAssembly.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 24.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BitcoinCore

struct RavencoinWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        try RavencoinWalletManager(wallet: input.wallet).then {
            let compressedKey = try Secp256k1Key(with: input.wallet.publicKey.blockchainKey).compress()

            let bitcoinManager = BitcoinManager(
                networkParams: input.blockchain.isTestnet ? RavencoinTestNetworkParams() : RavencoinMainNetworkParams(),
                walletPublicKey: input.wallet.publicKey.blockchainKey,
                compressedWalletPublicKey: compressedKey,
                bip: .bip44
            )

            $0.txBuilder = BitcoinTransactionBuilder(
                bitcoinManager: bitcoinManager,
                addresses: input.wallet.addresses
            )

            let blockchain = input.blockchain
            let providers: [AnyBitcoinNetworkProvider] = APIResolver(blockchain: blockchain, config: input.blockchainSdkConfig)
                .resolveProviders(apiInfos: input.apiInfo) { nodeInfo, providerType in
                    switch providerType {
                    case .nowNodes:
                        networkProviderAssembly.makeBlockBookUtxoProvider(
                            with: input,
                            for: .nowNodes
                        ).eraseToAnyBitcoinNetworkProvider()
                    default:
                        RavencoinNetworkProvider(
                            host: nodeInfo.link,
                            provider: .init(configuration: input.networkConfig)
                        )
                        .eraseToAnyBitcoinNetworkProvider()
                    }
                }

            $0.networkService = BitcoinNetworkService(providers: providers)
        }
    }
}
