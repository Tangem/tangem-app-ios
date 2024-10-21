//
//  MantleWalletAssembly.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 15.07.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MantleWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        guard let chainId = input.blockchain.chainId else {
            throw EthereumWalletAssemblyError.chainIdNotFound
        }

        let providers = networkProviderAssembly.makeEthereumJsonRpcProviders(with: input)
        let txBuilder = EthereumTransactionBuilder(chainId: chainId)
        let networkService = EthereumNetworkService(
            decimals: input.blockchain.decimalCount,
            providers: providers,
            blockcypherProvider: nil,
            abiEncoder: WalletCoreABIEncoder()
        )

        let addressConverter = EthereumAddressConverterFactory().makeConverter(for: input.blockchain)

        return MantleWalletManager(
            wallet: input.wallet,
            addressConverter: addressConverter,
            txBuilder: txBuilder,
            networkService: networkService,
            allowsFeeSelection: input.blockchain.allowsFeeSelection)
    }
}
