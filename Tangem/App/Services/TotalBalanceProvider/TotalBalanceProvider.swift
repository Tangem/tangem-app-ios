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

class TotalBalanceProvider {
    private let userWalletId: UserWalletId
    private let walletModelsManager: WalletModelsManager
    private let derivationManager: DerivationManager?

    private let queue = DispatchQueue(label: "com.tangem.TotalBalanceProvider")
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
        let balanceStatePublisher = walletModelsManager
            .walletModelsPublisher
            .removeDuplicates()
            .receive(on: queue)
            .withWeakCaptureOf(self)
            .flatMap { balanceProvider, walletModels in
                if walletModels.isEmpty {
                    return Just(TotalBalanceState.loaded(balance: 0)).eraseToAnyPublisher()
                }

                return walletModels.map { walletModel in
                    walletModel.fiatTotalTokenBalanceProvider
                        .balanceTypePublisher
                        .map { (item: walletModel.tokenItem, balance: $0) }
                }
                // Collect any/all changes in wallet models
                .combineLatest()
                .map { balanceProvider.mapToTotalBalance(balances: $0) }
                .eraseToAnyPublisher()
            }

        walletModelsSubscription = Publishers.CombineLatest(
            balanceStatePublisher,
            hasEntriesWithoutDerivationPublisher
        )
        .withWeakCaptureOf(self)
        .sink { balanceProvider, input in
            let (state, hasEntriesWithoutDerivation) = input
            balanceProvider.updateState(state: state, hasEntriesWithoutDerivation: hasEntriesWithoutDerivation)
        }
    }

    func updateState(state: TotalBalanceState, hasEntriesWithoutDerivation: Bool) {
        guard !hasEntriesWithoutDerivation else {
            totalBalanceSubject.send(.empty)
            return
        }

        totalBalanceSubject.send(state)

        // Analytics
        trackBalanceLoaded(state: state, tokensCount: walletModelsManager.walletModels.count)
        trackTokenBalanceLoaded(walletModels: walletModelsManager.walletModels)

        if case .loaded(let loadedBalance) = state {
            Analytics.logTopUpIfNeeded(balance: loadedBalance, for: userWalletId)
        }
    }

    // MARK: - Mapping

    func mapToTotalBalance(balances: [(item: TokenItem, balance: TokenBalanceType)]) -> TotalBalanceState {
        // Some not start loading yet
        let hasEmpty = balances.contains { $0.balance.isEmpty(for: .noData) }
        if hasEmpty {
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

        return .loaded(balance: loadedBalance)
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

    func mapToBalanceParameterValue(state: TotalBalanceState) -> Analytics.ParameterValue? {
        switch state {
        case .empty: .noRate
        case .loading: .none
        case .failed: .blockchainError
        case .loaded(let balance) where balance > .zero: .full
        case .loaded(let balance): .empty
        }
    }

    // MARK: - Analytics

    func trackBalanceLoaded(state: TotalBalanceState, tokensCount: Int) {
        guard let balance = mapToBalanceParameterValue(state: state) else {
            return
        }

        Analytics.log(
            event: .balanceLoaded,
            params: [
                .balance: balance.rawValue,
                .tokensCount: tokensCount.description,
            ],
            limit: .userWalletSession(userWalletId: userWalletId)
        )
    }

    func trackTokenBalanceLoaded(walletModels: [WalletModel]) {
        let trackedItems = walletModels.compactMap { walletModel -> (symbol: String, balance: Decimal)? in
            switch (walletModel.tokenItem.blockchain, walletModel.fiatTotalTokenBalanceProvider.balanceType) {
            case (.polkadot, .loaded(let balance)): (symbol: walletModel.tokenItem.currencySymbol, balance: balance)
            case (.kusama, .loaded(let balance)): (symbol: walletModel.tokenItem.currencySymbol, balance: balance)
            case (.azero, .loaded(let balance)): (symbol: walletModel.tokenItem.currencySymbol, balance: balance)
            // Other don't tracking
            default: .none
            }
        }

        trackedItems.forEach { symbol, balance in
            let positiveBalance = balance > 0

            Analytics.log(
                event: .tokenBalanceLoaded,
                params: [
                    .token: symbol,
                    .state: positiveBalance ? Analytics.ParameterValue.full.rawValue : Analytics.ParameterValue.empty.rawValue,
                ],
                limit: .userWalletSession(userWalletId: userWalletId, extraEventId: symbol)
            )
        }
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
