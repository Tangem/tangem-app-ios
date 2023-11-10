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

    private let walletModelsManager: WalletModelsManager
    private let derivationManager: DerivationManager?

    private let totalBalanceSubject = CurrentValueSubject<LoadingValue<TotalBalance>, Never>(.loading)

    private var walletModelsSubscription: AnyCancellable?
    private var updateSubscription: AnyCancellable?

    init(
        walletModelsManager: WalletModelsManager,
        derivationManager: DerivationManager?
    ) {
        self.walletModelsManager = walletModelsManager
        self.derivationManager = derivationManager

        bind()
    }
}

// MARK: - TotalBalanceProviding protocol conformance

extension TotalBalanceProvider: TotalBalanceProviding {
    func totalBalancePublisher() -> AnyPublisher<LoadingValue<TotalBalance>, Never> {
        totalBalanceSubject.eraseToAnyPublisher()
    }
}

// MARK: - Auxiliary types

extension TotalBalanceProvider {
    struct TotalBalance {
        let balance: Decimal?
        let currencyCode: String
        let hasError: Bool
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

                let hasLoadingWalletModels = walletModels.contains { $0.state.isLoading }

                // We should wait for balance loading to complete
                if hasLoadingWalletModels {
                    balanceProvider.totalBalanceSubject.send(.loading)
                    return
                }

                balanceProvider.updateTotalBalance(
                    withСurrencyCode: currencyCode,
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
                walletModels.allConforms { !$0.state.isLoading }
            }
            .withWeakCaptureOf(self)
            .sink { balanceProvider, input in
                let (walletModels, hasEntriesWithoutDerivation) = input
                balanceProvider.updateTotalBalance(
                    withСurrencyCode: AppSettings.shared.selectedCurrencyCode,
                    walletModels: walletModels,
                    hasEntriesWithoutDerivation: hasEntriesWithoutDerivation
                )
            }
    }

    func updateTotalBalance(
        withСurrencyCode currencyCode: String,
        walletModels: [WalletModel],
        hasEntriesWithoutDerivation: Bool
    ) {
        if hasEntriesWithoutDerivation {
            totalBalanceSubject.send(.loaded(.init(balance: nil, currencyCode: currencyCode, hasError: false)))
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

        for token in walletModels {
            if case .failed = token.state {
                hasCryptoError = true
            }

            if !token.state.isSuccesfullyLoaded {
                balance = nil
                break
            }

            let currentValue = balance ?? 0
            balance = currentValue + (token.fiatValue ?? 0)

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
            Analytics.logTopUpIfNeeded(balance: balance)
        }

        Analytics.log(
            .balanceLoaded,
            params: [
                .balance: mapToBalanceParameterValue(
                    hasCryptoError: hasCryptoError,
                    hasError: hasError,
                    balance: balance
                ),
            ]
        )

        return TotalBalance(balance: balance, currencyCode: currencyCode, hasError: hasError)
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
