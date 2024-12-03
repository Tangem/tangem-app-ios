//
//  TotalBalanceProvider.swift
//  Tangem
//
//  Created by Sergey Balashov on 16.09.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import BlockchainSdk

class TotalBalanceProvider {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let userWalletId: UserWalletId
    private let walletModelsManager: WalletModelsManager
    private let derivationManager: DerivationManager?

    private let totalBalanceSubject = CurrentValueSubject<LoadingValue<TotalBalance>, Never>(.loading)

    private var walletModelsSubscription: AnyCancellable?
    private var updateSubscription: AnyCancellable?

    init(
        userWalletId: UserWalletId,
        walletModelsManager: WalletModelsManager,
        derivationManager: DerivationManager?
    ) {
        self.userWalletId = userWalletId
        self.walletModelsManager = walletModelsManager
        self.derivationManager = derivationManager

        bind()
    }
}

// MARK: - TotalBalanceProviding protocol conformance

extension TotalBalanceProvider: TotalBalanceProviding {
    var totalBalancePublisher: AnyPublisher<LoadingValue<TotalBalance>, Never> {
        totalBalanceSubject.eraseToAnyPublisher()
    }
}

// MARK: - Private implementation

private extension TotalBalanceProvider {
    func bind() {
        let hasEntriesWithoutDerivationPublisher = derivationManager?.hasPendingDerivations ?? .just(output: false)

        // Subscription to handle token changes
        walletModelsSubscription = walletModelsManager
            .walletModelsPublisher
            .combineLatest(
                AppSettings.shared.$selectedCurrencyCode.delay(for: 0.3, scheduler: DispatchQueue.main),
                hasEntriesWithoutDerivationPublisher
            )
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { balanceProvider, input in
                let (walletModels, currencyCode, hasEntriesWithoutDerivation) = input

                balanceProvider.updateSubscription = nil

                if !walletModels.isEmpty {
                    balanceProvider.subscribeToUpdates(
                        walletModels: walletModels,
                        hasEntriesWithoutDerivation: hasEntriesWithoutDerivation
                    )
                }

                let hasLoadingWalletModels = walletModels.contains { $0.isLoading }

                // We should wait for balance loading to complete
                if hasLoadingWalletModels {
                    balanceProvider.totalBalanceSubject.send(.loading)
                    return
                }

                balanceProvider.updateTotalBalance(
                    withCurrencyCode: currencyCode,
                    walletModels: walletModels,
                    hasEntriesWithoutDerivation: hasEntriesWithoutDerivation
                )
            }
    }

    func subscribeToUpdates(walletModels: [WalletModel], hasEntriesWithoutDerivation: Bool) {
        // Subscription to handle balance loading completion

        updateSubscription = walletModels
            .map(\.walletDidChangePublisher)
            .merge()
            .mapToValue((walletModels, hasEntriesWithoutDerivation))
            .filter { walletModels, _ in
                // We can still have loading items
                walletModels.allConforms { !$0.isLoading }
            }
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { balanceProvider, input in
                let (walletModels, hasEntriesWithoutDerivation) = input
                balanceProvider.updateTotalBalance(
                    withCurrencyCode: AppSettings.shared.selectedCurrencyCode,
                    walletModels: walletModels,
                    hasEntriesWithoutDerivation: hasEntriesWithoutDerivation
                )
            }
    }

    func updateTotalBalance(
        withCurrencyCode currencyCode: String,
        walletModels: [WalletModel],
        hasEntriesWithoutDerivation: Bool
    ) {
        if hasEntriesWithoutDerivation {
            totalBalanceSubject.send(.loaded(.init(balance: nil, currencyCode: currencyCode, hasError: false, allTokensBalancesIncluded: false)))
            return
        }

        let totalBalance = mapToTotalBalance(
            currencyCode: currencyCode,
            walletModels: walletModels,
            hasEntriesWithoutDerivation: hasEntriesWithoutDerivation
        )
        totalBalanceSubject.send(.loaded(totalBalance))
    }

    func mapToTotalBalance(
        currencyCode: String,
        walletModels: [WalletModel],
        hasEntriesWithoutDerivation: Bool
    ) -> TotalBalance {
        var hasError = false
        var balance: Decimal?
        var hasCryptoError = false
        var allTokensBalancesIncluded = true

        for token in walletModels {
            if case .failed = token.state {
                hasCryptoError = true
            }

            if !token.isSuccessfullyLoaded {
                balance = nil
                break
            }

            let currentValue = balance ?? 0
            let allBalance = token.totalBalance
            balance = currentValue + (allBalance.fiat ?? 0)
            if allBalance.fiat == nil, !token.isCustom {
                allTokensBalancesIncluded = false
            }

            if token.rateFormatted.isEmpty {
                // Just show warning for custom tokens
                if token.isCustom {
                    hasError = true
                } else {
                    balance = nil
                    break
                }
            }
        }

        // It is also empty when derivation is missing
        if let balance, !hasEntriesWithoutDerivation {
            Analytics.logTopUpIfNeeded(balance: balance, for: userWalletId)
        }

        Analytics.log(
            .balanceLoaded,
            params: [
                .balance: mapToBalanceParameterValue(
                    hasCryptoError: hasCryptoError,
                    hasError: hasError,
                    balance: balance
                ),
            ],
            limit: .userWalletSession(userWalletId: userWalletId)
        )

        let mainCoinModels = walletModels.filter { $0.isMainToken }
        let trackedModels = mainCoinModels.filter {
            switch $0.blockchainNetwork.blockchain {
            case .polkadot, .kusama, .azero:
                return true
            default:
                return false
            }
        }

        for trackedModel in trackedModels {
            let balanceValue = trackedModel.balanceValue ?? 0

            Analytics.log(
                event:
                .tokenBalanceLoaded,
                params: [
                    .token: trackedModel.blockchainNetwork.blockchain.currencySymbol,
                    .state: balanceValue > 0 ? Analytics.ParameterValue.full.rawValue : Analytics.ParameterValue.empty.rawValue,
                ],
                limit: .userWalletSession(userWalletId: userWalletId, extraEventId: trackedModel.blockchainNetwork.blockchain.currencySymbol)
            )
        }

        return TotalBalance(
            balance: balance,
            currencyCode: currencyCode,
            hasError: hasError,
            allTokensBalancesIncluded: allTokensBalancesIncluded
        )
    }

    private func mapToBalanceParameterValue(
        hasCryptoError: Bool,
        hasError: Bool,
        balance: Decimal?
    ) -> Analytics.ParameterValue {
        if hasCryptoError {
            return .blockchainError
        }

        if hasError {
            return .customToken
        }

        if let balance {
            return balance > .zero ? .full : .empty
        }

        return .noRate
    }
}
