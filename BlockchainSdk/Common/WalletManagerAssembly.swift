//
//  WalletManagerAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 31.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

/// Input data for assembly wallet manager
struct WalletManagerAssemblyInput {
    let wallet: Wallet
    let pairPublicKey: Data?
    let blockchainSdkConfig: BlockchainSdkConfig
    let blockchainSdkDependencies: BlockchainSdkDependencies
    let apiInfo: [NetworkProviderType]
}

extension WalletManagerAssemblyInput: NetworkProviderAssemblyInput {
    var blockchain: Blockchain {
        wallet.blockchain
    }

    var networkConfig: NetworkProviderConfiguration {
        blockchainSdkConfig.networkProviderConfiguration(for: blockchain)
    }
}

/// Main assembly wallet manager interface
protocol WalletManagerAssembly {
    /// Assembly to access any providers
    var networkProviderAssembly: NetworkProviderAssembly { get }

    // MARK: - Wallet Assembly

    /// Function that creates WalletManager according to input data
    /// - Parameter input: Input that contains information about blockchain, SdkConfig, network settings
    /// - Returns: WalletManager for specified blockchain
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager
}

extension WalletManagerAssembly {
    var networkProviderAssembly: NetworkProviderAssembly {
        return NetworkProviderAssembly()
    }
}
