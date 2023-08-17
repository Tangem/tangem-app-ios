//
//  TotalBalanceProvider.swift
//  Tangem
//
//  Created by Sergey Balashov on 16.09.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import BlockchainSdk

class TotalBalanceProvider {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let walletModelsManager: WalletModelsManager
    private let derivationManager: DerivationManager?
    private let totalBalanceSubject = CurrentValueSubject<LoadingValue<TotalBalance>, Never>(.loading)
    private var refreshSubscription: AnyCancellable?
    private var bag: Set<AnyCancellable> = .init()
    private var updateSubscription: AnyCancellable?

    init(walletModelsManager: WalletModelsManager, derivationManager: DerivationManager?) {
        self.walletModelsManager = walletModelsManager
        self.derivationManager = derivationManager
        bind()
    }
}

// MARK: - TotalBalanceProviding

extension TotalBalanceProvider: TotalBalanceProviding {
    func totalBalancePublisher() -> AnyPublisher<LoadingValue<TotalBalance>, Never> {
        totalBalanceSubject.eraseToAnyPublisher()
    }
}

private extension TotalBalanceProvider {
    func bind() {
        let hasEntriesWithoutDerivationPublisher = derivationManager?.hasPendingDerivations ?? .just(output: false)

        // Subscription to handle token changes
        walletModelsManager.walletModelsPublisher
            .combineLatest(
                AppSettings.shared.$selectedCurrencyCode.delay(for: 0.3, scheduler: DispatchQueue.main),
                hasEntriesWithoutDerivationPublisher
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] walletModels, currencyCode, hasEntriesWithoutDerivation in
                self?.updateSubscription = nil

                if !walletModels.isEmpty {
                    self?.subscribeToUpdates(walletModels, hasEntriesWithoutDerivation)
                }

                let hasLoading = !walletModels.filter { $0.state.isLoading }.isEmpty

                // We should wait for balance loading to complete
                if hasLoading {
                    self?.totalBalanceSubject.send(.loading)
                    return
                }

                self?.updateTotalBalance(with: currencyCode, walletModels, hasEntriesWithoutDerivation)
            }
            .store(in: &bag)
    }

    private func subscribeToUpdates(_ walletModels: [WalletModel], _ hasEntriesWithoutDerivation: Bool) {
        // Subscription to handle balance loading completion

        updateSubscription = Publishers.MergeMany(walletModels.map { $0.walletDidChangePublisher })
            .map { _ in (walletModels, hasEntriesWithoutDerivation) }
            .debounce(for: 0.2, scheduler: DispatchQueue.main) // Hide skeleton with delay
            .filter { walletModels, _ in
                // We can still have loading items
                walletModels.allConforms { !$0.state.isLoading }
            }
            .sink { [weak self] walletModels, hasEntriesWithoutDerivation in
                self?.updateTotalBalance(with: AppSettings.shared.selectedCurrencyCode, walletModels, hasEntriesWithoutDerivation)
            }
    }

    func updateTotalBalance(with currencyCode: String, _ walletModels: [WalletModel], _ hasEntriesWithoutDerivation: Bool) {
        guard !hasEntriesWithoutDerivation else {
            totalBalanceSubject.send(.loaded(.init(balance: nil, currencyCode: currencyCode, hasError: false)))
            return
        }

        let totalBalance = mapToTotalBalance(currencyCode: currencyCode, walletModels, hasEntriesWithoutDerivation)
        totalBalanceSubject.send(.loaded(totalBalance))
    }

    func mapToTotalBalance(currencyCode: String, _ walletModels: [WalletModel], _ hasEntriesWithoutDerivation: Bool) -> TotalBalance {
        var hasError = false
        var balance: Decimal?

        for token in walletModels {
            if !token.state.isSuccesfullyLoaded {
                balance = nil
                break
            }

            let roundedTokenFiatValue: Decimal
            if let tokenFiatValue = token.fiatValue,
               !tokenFiatValue.isZero {
                roundedTokenFiatValue = max(0.01, tokenFiatValue)
            } else {
                roundedTokenFiatValue = .zero
            }

            let currentValue = balance ?? 0
            balance = currentValue + roundedTokenFiatValue

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

        return TotalBalance(balance: balance, currencyCode: currencyCode, hasError: hasError)
    }
}

extension TotalBalanceProvider {
    struct TotalBalance {
        let balance: Decimal?
        let currencyCode: String
        let hasError: Bool
    }
}
