//
//  SwappingTokenListViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemSwapping
import enum BlockchainSdk.Blockchain

final class SwappingTokenListViewModel: ObservableObject, Identifiable {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    // MARK: - ViewState

    // I can't use @Published here, because of swiftui redraw perfomance drop
    var searchText = CurrentValueSubject<String, Never>("")

    @Published var navigationTitleViewModel: BlockchainNetworkNavigationTitleViewModel?
    @Published var userItems: [SwappingTokenItemViewModel] = []
    @Published var otherItems: [SwappingTokenItemViewModel] = []

    var hasNextPage: Bool {
        dataLoader.canFetchMore
    }

    // MARK: - Dependencies

    private let userCurrenciesProvider: UserCurrenciesProviding
    private let tokenIconURLBuilder: TokenIconURLBuilding
    private let currencyMapper: CurrencyMapping
    private let walletDataProvider: SwappingWalletDataProvider
    private let fiatRatesProvider: FiatRatesProviding
    private unowned let coordinator: SwappingTokenListRoutable

    private let blockchain: Blockchain
    private let sourceCurrency: Currency
    private var userCurrencies: [Currency] = []
    private var bag: Set<AnyCancellable> = []
    private lazy var dataLoader: ListDataLoader = setupLoader()

    private var setupUserItemsSectionTask: Task<Void, Error>? {
        didSet { oldValue?.cancel() }
    }

    init(
        blockchain: Blockchain,
        sourceCurrency: Currency,
        userCurrenciesProvider: UserCurrenciesProviding,
        tokenIconURLBuilder: TokenIconURLBuilding,
        currencyMapper: CurrencyMapping,
        walletDataProvider: SwappingWalletDataProvider,
        fiatRatesProvider: FiatRatesProviding,
        coordinator: SwappingTokenListRoutable
    ) {
        self.blockchain = blockchain
        self.sourceCurrency = sourceCurrency
        self.userCurrenciesProvider = userCurrenciesProvider
        self.tokenIconURLBuilder = tokenIconURLBuilder
        self.currencyMapper = currencyMapper
        self.walletDataProvider = walletDataProvider
        self.fiatRatesProvider = fiatRatesProvider
        self.coordinator = coordinator

        setupNavigationTitleView()
        bind()
    }

    func onAppear() {
        setupUserItemsSection()
        fetch()
    }

    func onDisappear() {
        setupUserItemsSectionTask = nil
    }

    func fetch() {
        dataLoader.fetch(searchText.value)
    }
}

private extension SwappingTokenListViewModel {
    func setupNavigationTitleView() {
        navigationTitleViewModel = .init(
            title: Localization.swappingTokenListTitle,
            iconURL: tokenIconURLBuilder.iconURL(id: sourceCurrency.blockchain.id, size: .small),
            network: sourceCurrency.blockchain.name
        )
    }

    func setupUserItemsSection() {
        setupUserItemsSectionTask = runTask(in: self) { obj in
            obj.userCurrencies = await obj.userCurrenciesProvider.getCurrencies(
                blockchain: obj.sourceCurrency.blockchain
            )

            /// Currencies which should be in user items section
            let currencies = obj.userCurrencies.filter { obj.sourceCurrency != $0 }
            var items: [SwappingTokenItemViewModel] = []
            var currenciesToLoadBalance: [Currency] = []

            currencies.forEach { currency in
                guard let balance = obj.walletDataProvider.getBalance(for: currency),
                      let fiatBalance = obj.fiatRatesProvider.getFiat(for: currency, amount: balance) else {
                    // If we haven't cache for this currency
                    currenciesToLoadBalance.append(currency)
                    return
                }

                let viewModel = obj.mapToSwappingTokenItemViewModel(
                    currency: currency,
                    balance: CurrencyAmount(value: balance, currency: currency),
                    fiatBalance: fiatBalance
                )

                items.append(viewModel)
            }

            await runOnMain {
                obj.userItems = items
            }

            // If we have currencies without balance in the cache
            guard !currenciesToLoadBalance.isEmpty else {
                // All currencies balances was loaded
                return
            }

            guard !Task.isCancelled else { return }

            AppLog.shared.debug("Start loading balances for currencies: \(currenciesToLoadBalance)")
            // Create a task group for collecting all updates in single array
            let currencyBalances = await withTaskGroup(of: CurrencyAmount.self) { taskGroup in
                for currency in currenciesToLoadBalance {
                    // Run a parallel asynchronous task and collect it into the group
                    _ = taskGroup.addTaskUnlessCancelled {
                        do {
                            let balance = try await obj.walletDataProvider.getBalance(for: currency)
                            return CurrencyAmount(value: balance, currency: currency)
                        } catch {
                            AppLog.shared.debug("Loading balance for currency \(currency) throw error")
                            AppLog.shared.error(error)
                            return CurrencyAmount(value: 0, currency: currency)
                        }
                    }
                }

                // Await when all child tasks will be done
                // And map the result array into [Currency: Decimal] to filter out duplicate currencies
                return await taskGroup.reduce(into: [:]) { $0[$1.currency] = $1.value }
            }

            guard !Task.isCancelled else { return }

            let fiatBalances = try await obj.fiatRatesProvider.getFiat(for: currencyBalances)
            fiatBalances.forEach { currency, fiatBalance in
                guard let balance = currencyBalances[currency] else {
                    AppLog.shared.debug("Balance for currency \(currency) not found")
                    return
                }

                let viewModel = obj.mapToSwappingTokenItemViewModel(
                    currency: currency,
                    balance: CurrencyAmount(value: balance, currency: currency),
                    fiatBalance: fiatBalance
                )

                items.append(viewModel)
            }

            await runOnMain {
                obj.userItems = items
            }
        }
    }

    func bind() {
        searchText
            .dropFirst()
            .map { $0.trimmed() }
            .removeDuplicates()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sink { [weak self] string in
                self?.dataLoader.fetch(string)
            }
            .store(in: &bag)
    }

    func setupLoader() -> ListDataLoader {
        let dataLoader = ListDataLoader(supportedBlockchains: [blockchain], exchangeable: true)
        dataLoader.$items
            .receive(on: DispatchQueue.global())
            .map { [weak self] coinModels in
                coinModels.compactMap { self?.currencyMapper.mapToCurrency(coinModel: $0) }
            }
            .map { [weak self] currencies in
                currencies
                    .filter { currency in self?.userCurrencies.contains(currency) == false }
                    .compactMap { self?.mapToSwappingTokenItemViewModel(currency: $0) }
            }
            .receive(on: DispatchQueue.main)
            .receiveValue { [weak self] items in
                self?.otherItems = items
            }
            .store(in: &bag)

        return dataLoader
    }

    func userDidTap(_ currency: Currency) {
        Analytics.log(event: .swapSearchedTokenClicked, params: [.token: currency.symbol])
        coordinator.userDidTap(currency: currency)
    }

    func mapToSwappingTokenItemViewModel(
        currency: Currency,
        balance: CurrencyAmount? = nil,
        fiatBalance: Decimal? = nil
    ) -> SwappingTokenItemViewModel {
        SwappingTokenItemViewModel(
            tokenId: currency.id,
            iconURL: tokenIconURLBuilder.iconURL(id: currency.id, size: .large),
            name: currency.name,
            symbol: currency.symbol,
            balance: balance,
            fiatBalance: fiatBalance
        ) { [weak self] in
            self?.userDidTap(currency)
        }
    }
}
