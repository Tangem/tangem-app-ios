//
//  BitcoinCashWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import stellarsdk
import BitcoinCore

struct BitcoinCashWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        return try BitcoinWalletManager(wallet: input.wallet).then {
            let compressed = try Secp256k1Key(with: input.wallet.publicKey.blockchainKey).compress()
            let bitcoinManager = BitcoinManager(
                networkParams: input.blockchain.isTestnet ? BitcoinCashTestNetworkParams() : BitcoinCashNetworkParams(),
                walletPublicKey: compressed,
                compressedWalletPublicKey: compressed,
                bip: .bip44
            )

            $0.txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, addresses: input.wallet.addresses)

            // TODO: Add testnet support.
            // Maybe https://developers.cryptoapis.io/technical-documentation/general-information/what-we-support
            let providers: [AnyBitcoinNetworkProvider] = input.apiInfo.reduce(into: []) { partialResult, providerType in
                switch providerType {
                case .nowNodes:
                    if let bitcoinCashAddressService = AddressServiceFactory(blockchain: input.blockchain).makeAddressService() as? BitcoinCashAddressService {
                        partialResult.append(
                            networkProviderAssembly.makeBitcoinCashNowNodesNetworkProvider(
                                input: input,
                                bitcoinCashAddressService: bitcoinCashAddressService
                            )
                        )
                    }
                case .getBlock:
                    partialResult.append(networkProviderAssembly.makeBlockBookUtxoProvider(with: input, for: .getBlock).eraseToAnyBitcoinNetworkProvider())
                case .blockchair:
                    partialResult.append(
                        contentsOf: networkProviderAssembly.makeBlockchairNetworkProviders(endpoint: .bitcoinCash, with: input)
                    )
                default:
                    return
                }
            }

            $0.networkService = BitcoinCashNetworkService(providers: providers)
        }
    }
}
