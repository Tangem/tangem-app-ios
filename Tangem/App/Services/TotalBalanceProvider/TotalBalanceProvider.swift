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
    private let userWalletId: UserWalletId
    private let walletModelsManager: WalletModelsManager
    private let derivationManager: DerivationManager?

    private let totalBalanceSubject = CurrentValueSubject<TotalBalanceState, Never>(.loading(cached: .none))

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
    var totalBalancePublisher: AnyPublisher<TotalBalanceState, Never> {
        totalBalanceSubject.eraseToAnyPublisher()
    }
}

// MARK: - Private implementation

private extension TotalBalanceProvider {
    func bind() {
        let hasEntriesWithoutDerivationPublisher = derivationManager?.hasPendingDerivations ?? .just(output: false)

        // Subscription to handle token changes
        walletModelsSubscription = Publishers.CombineLatest(
            walletModelsManager.walletModelsPublisher,
            hasEntriesWithoutDerivationPublisher
        )
        .receive(on: DispatchQueue.main)
        .withWeakCaptureOf(self)
        .sink { balanceProvider, input in
            let (walletModels, hasEntriesWithoutDerivation) = input
            balanceProvider.contextDidChange(
                walletModels: walletModels, hasEntriesWithoutDerivation: hasEntriesWithoutDerivation
            )
        }
    }

    func contextDidChange(walletModels: [WalletModel], hasEntriesWithoutDerivation: Bool) {
        // Clear previous
        updateSubscription = nil

        trackTokenBalanceLoaded(walletModels: walletModels)

        let providers = walletModels.map { (tokenItem: $0.tokenItem, provider: $0.combineFiatBalanceProvider) }

        if !providers.isEmpty {
            // Setup updating listener
            subscribeToUpdates(providers: providers, hasEntriesWithoutDerivation: hasEntriesWithoutDerivation)
        }

        // Update with data which already have
        let balances = providers.map { (item: $0.tokenItem, balance: $0.provider.balanceType) }
        updateTotalBalance(
            balances: balances,
            hasEntriesWithoutDerivation: hasEntriesWithoutDerivation
        )
    }

    func subscribeToUpdates(providers: [(tokenItem: TokenItem, provider: TokenBalanceProvider)], hasEntriesWithoutDerivation: Bool) {
        // Subscription to handle balance loading completion
        updateSubscription = providers
            .map { $0.provider.balanceTypePublisher }
            .merge()
            .mapToValue(providers)
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { balanceProvider, providers in
                let balances = providers.map { (item: $0.tokenItem, balance: $0.provider.balanceType) }
                balanceProvider.updateTotalBalance(
                    balances: balances,
                    hasEntriesWithoutDerivation: hasEntriesWithoutDerivation
                )
            }
    }

    func updateTotalBalance(balances: [(item: TokenItem, balance: TokenBalanceType)], hasEntriesWithoutDerivation: Bool) {
        let state = mapToTotalBalance(balances: balances, hasEntriesWithoutDerivation: hasEntriesWithoutDerivation)
        totalBalanceSubject.send(state)
    }

    func mapToTotalBalance(balances: [(item: TokenItem, balance: TokenBalanceType)], hasEntriesWithoutDerivation: Bool) -> TotalBalanceState {
        // Some not start loading yet
        let hasEmpty = balances.contains { $0.balance.isEmpty(for: .noData) }
        if hasEntriesWithoutDerivation || hasEmpty {
            return .empty
        }

        if balances.isEmpty {
            return .loaded(balance: 0)
        }

        let hasLoading = balances.contains { $0.balance.isLoading }

        // Show it in loading state if only one is in loading process
        if hasLoading {
            let loadingBalance = loadingBalance(balances: balances.map(\.balance))
            return .loading(cached: loadingBalance)
        }

        let failureBalances = balances.filter { $0.balance.isFailure }
        let hasError = !failureBalances.isEmpty
        if hasError {
            // If has error and cached balance then show the failed state with cached balances
            let cachedBalance = failedBalance(balances: balances.map(\.balance))
            return .failed(cached: cachedBalance, failedItems: failureBalances.map(\.item))
        }

        guard let loadedBalance = loadedBalance(balances: balances) else {
            // some tokens don't have balance
            return .empty
        }

        // It is also empty when derivation is missing
        if !hasEntriesWithoutDerivation {
            Analytics.logTopUpIfNeeded(balance: loadedBalance, for: userWalletId)
        }

        let hasCustomToken = balances.contains { $0.balance.isEmpty(for: .custom) }
        let parameterValue = mapToBalanceParameterValue(
            hasBlockchainBalanceLoadingError: hasError,
            emptyRatesBecauseCustomToken: hasCustomToken,
            balance: loadedBalance
        )

        Analytics.log(
            event: .balanceLoaded,
            params: [
                .balance: parameterValue.rawValue,
                .tokensCount: String(balances.count),
            ],
            limit: .userWalletSession(userWalletId: userWalletId)
        )

        return .loaded(balance: loadedBalance)
    }

    func trackTokenBalanceLoaded(walletModels: [WalletModel]) {
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
            let positiveBalance = trackedModel.balanceState == .positive

            Analytics.log(
                event: .tokenBalanceLoaded,
                params: [
                    .token: trackedModel.blockchainNetwork.blockchain.currencySymbol,
                    .state: positiveBalance ? Analytics.ParameterValue.full.rawValue : Analytics.ParameterValue.empty.rawValue,
                ],
                limit: .userWalletSession(userWalletId: userWalletId, extraEventId: trackedModel.blockchainNetwork.blockchain.currencySymbol)
            )
        }
    }

    func loadingBalance(balances: [TokenBalanceType]) -> Decimal? {
        let cachedBalances = balances.compactMap { balanceType in
            switch balanceType {
            case .empty(.custom), .empty(.noAccount):
                return Decimal(0)
            case .loading(.some(let cached)), .failure(.some(let cached)):
                return cached.balance
            case .loaded(let balance):
                return balance
            default:
                return nil
            }
        }

        // Show loading balance only if all tokens have balance value
        if cachedBalances.count == balances.count {
            return cachedBalances.reduce(0, +)
        }

        return nil
    }

    func failedBalance(balances: [TokenBalanceType]) -> Decimal? {
        let cachedBalances = balances.compactMap { balanceType in
            switch balanceType {
            case .loading(.some(let cached)), .failure(.some(let cached)):
                return cached.balance
            case .loaded(let balance):
                return balance
            default:
                return nil
            }
        }

        if cachedBalances.isEmpty {
            return nil
        }

        return cachedBalances.reduce(0, +)
    }

    func loadedBalance(balances: [(item: TokenItem, balance: TokenBalanceType)]) -> Decimal? {
        let loadedBalance = balances.compactMap { balance in
            switch balance.balance {
            case .loaded(let balance):
                return balance
            // If we don't balance because custom token don't have rates
            // Or it's address with noAccount state
            // Just calculate it as `.zero`
            case .empty(.custom), .empty(.noAccount):
                return .zero
            default:
                assertionFailure("Balance not found \(balance.item.name)")
                return nil
            }
        }

        return loadedBalance.reduce(0, +)
    }

    func mapToBalanceParameterValue(
        hasBlockchainBalanceLoadingError: Bool,
        emptyRatesBecauseCustomToken: Bool,
        balance: Decimal?
    ) -> Analytics.ParameterValue {
        if hasBlockchainBalanceLoadingError {
            return .blockchainError
        }

        if emptyRatesBecauseCustomToken {
            return .customToken
        }

        if let balance {
            return balance > .zero ? .full : .empty
        }

        return .noRate
    }
}

private extension TokenBalanceType {
    /// Don't loaded balance for some reason (Haven't call update yet / noDerivation state)
    func isEmpty(for reason: EmptyReason) -> Bool {
        switch self {
        case .empty(let emptyReason): emptyReason == reason
        default: false
        }
    }
}
