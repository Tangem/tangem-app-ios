//
//  CommonExpressDestinationService.swift
//  Tangem
//
//  Created by Sergey Balashov on 14.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct CommonExpressDestinationService {
    @Injected(\.expressAvailabilityProvider) private var expressAvailabilityProvider: ExpressAvailabilityProvider
    @Injected(\.expressPendingTransactionsRepository) private var pendingTransactionRepository: ExpressPendingTransactionRepository

    private let walletModelsManager: WalletModelsManager
    private let expressRepository: ExpressRepository

    init(
        walletModelsManager: WalletModelsManager,
        expressRepository: ExpressRepository
    ) {
        self.walletModelsManager = walletModelsManager
        self.expressRepository = expressRepository
    }
}

// MARK: - ExpressDestinationService

extension CommonExpressDestinationService: ExpressDestinationService {
    func getDestination(source: WalletModel) async throws -> WalletModel {
        let availablePairs = await expressRepository.getPairs(from: source)
        let searchableWalletModels = walletModelsManager.walletModels.filter { wallet in
            let isNotSource = wallet.id != source.id
            let isAvailable = expressAvailabilityProvider.canSwap(tokenItem: wallet.tokenItem)
            let isNotCustom = !wallet.isCustom
            let hasPair = availablePairs.contains(where: { $0.destination == wallet.expressCurrency })

            return isNotSource && isAvailable && isNotCustom && hasPair
        }

        AppLog.shared.debug("[Express] \(self) has searchableWalletModels: \(searchableWalletModels.map { ($0.expressCurrency, $0.fiatBalance) })")

        if let lastSwappedWallet = searchableWalletModels.first(where: { isLastTransactionWith(walletModel: $0) }) {
            AppLog.shared.debug("[Express] \(self) selected lastSwappedWallet: \(lastSwappedWallet.expressCurrency)")
            return lastSwappedWallet
        }

        let walletModelsWithPositiveBalance = searchableWalletModels.filter { ($0.fiatValue ?? 0) > 0 }

        // If all wallets without balance
        if walletModelsWithPositiveBalance.isEmpty, let first = searchableWalletModels.first {
            AppLog.shared.debug("[Express] \(self) has a zero wallets with positive balance then selected: \(first.expressCurrency)")
            return first
        }

        // If user has wallets with balance then sort they
        let sortedWallets = walletModelsWithPositiveBalance.sorted(by: { ($0.fiatValue ?? 0) > ($1.fiatValue ?? 0) })

        // Start searching destination with available providers
        if let maxBalanceWallet = sortedWallets.first {
            AppLog.shared.debug("[Express] \(self) selected maxBalanceWallet: \(maxBalanceWallet.expressCurrency)")
            return maxBalanceWallet
        }

        AppLog.shared.debug("[Express] \(self) couldn't find acceptable wallet")
        throw ExpressDestinationServiceError.destinationNotFound
    }
}

// MARK: - Private

private extension CommonExpressDestinationService {
    func isLastTransactionWith(walletModel: WalletModel) -> Bool {
        let transactions = pendingTransactionRepository.transactions
        let lastCurrency = transactions.last?.destinationTokenTxInfo.tokenItem.expressCurrency

        return walletModel.expressCurrency == lastCurrency
    }
}

extension CommonExpressDestinationService: CustomStringConvertible {
    var description: String {
        "ExpressDestinationService"
    }
}
