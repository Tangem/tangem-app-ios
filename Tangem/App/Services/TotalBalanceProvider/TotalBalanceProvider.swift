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

    private unowned let userWalletModel: UserWalletModel
    private let totalBalanceSubject = CurrentValueSubject<LoadingValue<TotalBalance>, Never>(.loading)
    private var refreshSubscription: AnyCancellable?
    private let userWalletAmountType: Amount.AmountType?
    private var bag: Set<AnyCancellable> = .init()
    private var updateSubscription: AnyCancellable?

    init(userWalletModel: UserWalletModel, userWalletAmountType: Amount.AmountType?) {
        self.userWalletModel = userWalletModel
        self.userWalletAmountType = userWalletAmountType
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
        let hasEntriesWithoutDerivationPublisher = userWalletModel
            .subscribeToEntriesWithoutDerivation()
            .map { !$0.isEmpty }

        // Subscription to handle token changes
        userWalletModel.subscribeToWalletModels()
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

        updateSubscription = Publishers.MergeMany(
            walletModels.map { $0
                .walletDidChange
                .filter { !$0.isLoading } // subscribe to all the walletDidChange events
                // This delay has been added because `walletDidChange` pushed the changes on `willSet`
                .delay(for: 0.1, scheduler: DispatchQueue.main)
            })
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
        let tokenItemViewModels = getTokenItemViewModels(from: walletModels)

        var hasError = false
        var balance: Decimal?

        for token in tokenItemViewModels {
            if !token.state.isSuccesfullyLoaded {
                balance = nil
                break
            }

            let currentValue = balance ?? 0
            balance = currentValue + token.fiatValue

            if token.rate.isEmpty {
                // Just show wawning for custom tokens
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

    func getTokenItemViewModels(from walletModels: [WalletModel]) -> [LegacyTokenItemViewModel] {
        walletModels
            .flatMap { $0.legacyMultiCurrencyViewModel() }
            .filter { model in
                guard let amountType = userWalletAmountType else { return true }

                return model.amountType == amountType
            }
    }
}

extension TotalBalanceProvider {
    struct TotalBalance {
        let balance: Decimal?
        let currencyCode: String
        let hasError: Bool
    }
}
