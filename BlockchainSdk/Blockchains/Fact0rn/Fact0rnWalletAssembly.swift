//
//  Fact0rnWalletAssembly.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 11.12.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BitcoinCore

struct Fact0rnWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        try BitcoinWalletManager(wallet: input.wallet).then {
            let compressedKey = try Secp256k1Key(with: input.wallet.publicKey.blockchainKey).compress()

            let bitcoinManager = BitcoinManager(
                networkParams: Fact0rnMainNetworkParams(),
                walletPublicKey: input.wallet.publicKey.blockchainKey,
                compressedWalletPublicKey: compressedKey,
                bip: .bip84
            )

            $0.txBuilder = BitcoinTransactionBuilder(
                bitcoinManager: bitcoinManager,
                addresses: input.wallet.addresses
            )

            let anyPoviders: [AnyBitcoinNetworkProvider] = APIResolver(blockchain: input.blockchain, config: input.blockchainSdkConfig)
                .resolveProviders(apiInfos: input.apiInfo, factory: { nodeInfo, _ in
                    let electrumWebSocketProvider = ElectrumWebSocketProvider(url: nodeInfo.url)
                    let provider = Fact0rnNetworkProvider(
                        provider: electrumWebSocketProvider,
                        decimalValue: input.blockchain.decimalValue,
                        decimalCount: input.blockchain.decimalCount
                    )

                    return AnyBitcoinNetworkProvider(provider)
                })

            $0.networkService = BitcoinNetworkService(providers: anyPoviders)
        }
    }
}
