//
//  EthereumChildWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import stellarsdk
import BitcoinCore

struct EthereumWalletAssembly: WalletManagerAssembly {
    
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        guard let chainId = input.blockchain.chainId else {
            throw EthereumWalletAssemblyError.chainIdNotFound
        }

        let blockcypherProvider: BlockcypherNetworkProvider? = {
            switch input.blockchain {
            case .ethereum:
                return BlockcypherNetworkProvider(
                    endpoint: .ethereum,
                    tokens: input.blockchainSdkConfig.blockcypherTokens,
                    configuration: input.networkConfig
                )
            default:
                return nil
            }
        }()

        let txBuilder = EthereumTransactionBuilder(chainId: chainId)
        let networkService = EthereumNetworkService(
            decimals: input.blockchain.decimalCount,
            providers: networkProviderAssembly.makeEthereumJsonRpcProviders(with: input),
            blockcypherProvider: blockcypherProvider,
            abiEncoder: WalletCoreABIEncoder()
        )

        let addressConverter = EthereumAddressConverterFactory().makeConverter(for: input.blockchain)

        return EthereumWalletManager(
            wallet: input.wallet,
            addressConverter: addressConverter,
            txBuilder: txBuilder,
            networkService: networkService,
            allowsFeeSelection: input.blockchain.allowsFeeSelection
        )
    }
}

enum EthereumWalletAssemblyError: Error {
    case chainIdNotFound
}
