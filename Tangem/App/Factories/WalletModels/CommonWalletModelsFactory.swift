//
//  CommonWalletModelsFactory.swift
//  Tangem
//
//  Created by Alexander Osokin on 19.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk
import TangemStaking

struct CommonWalletModelsFactory {
    private let config: UserWalletConfig

    init(config: UserWalletConfig) {
        self.config = config
    }

    private func isDerivationDefault(blockchain: Blockchain, derivationPath: DerivationPath?) -> Bool {
        guard let derivationStyle = config.derivationStyle else {
            return true
        }

        let defaultDerivation = blockchain.derivationPath(for: derivationStyle)
        return derivationPath == defaultDerivation
    }

    private func makeTransactionHistoryService(tokenItem: TokenItem, addresses: [String]) -> TransactionHistoryService? {
        if addresses.count == 1, let address = addresses.first {
            let factory = TransactionHistoryFactoryProvider().factory

            guard let provider = factory.makeProvider(for: tokenItem.blockchain) else {
                return nil
            }

            return CommonTransactionHistoryService(
                tokenItem: tokenItem,
                address: address,
                transactionHistoryProvider: provider
            )
        }

        let multiAddressProviders: [String: TransactionHistoryProvider] = addresses.reduce(into: [:]) { result, address in
            let factory = TransactionHistoryFactoryProvider().factory
            if let provider = factory.makeProvider(for: tokenItem.blockchain) {
                result[address] = provider
            }
        }

        guard !multiAddressProviders.isEmpty else {
            return nil
        }

        return MultipleAddressTransactionHistoryService(
            tokenItem: tokenItem,
            addresses: addresses,
            transactionHistoryProviders: multiAddressProviders.compactMapValues { $0 }
        )
    }

    func makeStakingManager(publicKey: Data, tokenItem: TokenItem, address: String) -> StakingManager? {
        let featureProvider = StakingFeatureProvider(config: config)

        guard let integrationId = featureProvider.yieldId(for: tokenItem),
              let item = tokenItem.stakingTokenItem else {
            return nil
        }

        let wallet = StakingWallet(
            item: item,
            address: address,
            publicKey: publicKey
        )
        return StakingDependenciesFactory().makeStakingManager(integrationId: integrationId, wallet: wallet)
    }
}

extension CommonWalletModelsFactory: WalletModelsFactory {
    func makeWalletModels(from walletManager: WalletManager) -> [WalletModel] {
        var types: [Amount.AmountType] = [.coin]
        types += walletManager.cardTokens.map { Amount.AmountType.token(value: $0) }
        return makeWalletModels(for: types, walletManager: walletManager)
    }

    func makeWalletModels(for types: [Amount.AmountType], walletManager: WalletManager) -> [WalletModel] {
        var models: [WalletModel] = []

        let currentBlockchain = walletManager.wallet.blockchain
        let currentDerivation = walletManager.wallet.publicKey.derivationPath
        let isMainCoinCustom = !isDerivationDefault(blockchain: currentBlockchain, derivationPath: currentDerivation)
        let blockchainNetwork = BlockchainNetwork(currentBlockchain, derivationPath: currentDerivation)
        if types.contains(.coin) {
            let tokenItem: TokenItem = .blockchain(blockchainNetwork)
            let transactionHistoryService = makeTransactionHistoryService(
                tokenItem: tokenItem,
                addresses: walletManager.wallet.addresses.map { $0.value }
            )
            let shouldPerformHealthCheck = shouldPerformHealthCheck(blockchain: currentBlockchain, amountType: .coin)
            let mainCoinModel = WalletModel(
                walletManager: walletManager,
                stakingManager: makeStakingManager(
                    publicKey: walletManager.wallet.publicKey.blockchainKey,
                    tokenItem: tokenItem,
                    address: walletManager.wallet.address
                ),
                transactionHistoryService: transactionHistoryService,
                amountType: .coin,
                shouldPerformHealthCheck: shouldPerformHealthCheck,
                isCustom: isMainCoinCustom
            )
            models.append(mainCoinModel)
        }

        walletManager.cardTokens.forEach { token in
            let amountType: Amount.AmountType = .token(value: token)
            if types.contains(amountType) {
                let isTokenCustom = isMainCoinCustom || token.id == nil
                let tokenItem: TokenItem = .token(token, blockchainNetwork)
                let transactionHistoryService = makeTransactionHistoryService(
                    tokenItem: tokenItem,
                    addresses: walletManager.wallet.addresses.map { $0.value }
                )
                let shouldPerformHealthCheck = shouldPerformHealthCheck(blockchain: currentBlockchain, amountType: amountType)
                let tokenModel = WalletModel(
                    walletManager: walletManager,
                    stakingManager: makeStakingManager(
                        publicKey: walletManager.wallet.publicKey.blockchainKey,
                        tokenItem: tokenItem,
                        address: walletManager.wallet.address
                    ),
                    transactionHistoryService: transactionHistoryService,
                    amountType: amountType,
                    shouldPerformHealthCheck: shouldPerformHealthCheck,
                    isCustom: isTokenCustom
                )
                models.append(tokenModel)
            }
        }

        return models
    }

    /// For now, an account health check is only required for Polkadot Mainnet.
    private func shouldPerformHealthCheck(blockchain: Blockchain, amountType: Amount.AmountType) -> Bool {
        switch (blockchain, amountType) {
        case (.polkadot(_, let isTestnet), .coin):
            return !isTestnet
        default:
            return false
        }
    }
}
