//
//  SwappingTokenListViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemExchange

final class SwappingTokenListViewModel: ObservableObject, Identifiable {
    /// For SwiftUI sheet logic
    let id = UUID()

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

    private let tokenIconURLBuilder: TokenIconURLBuilding
    private let currencyMapper: CurrencyMapping
    private let walletDataProvider: WalletDataProvider
    private let fiatRatesProvider: FiatRatesProviding
    private unowned let coordinator: SwappingTokenListRoutable

    private let sourceCurrency: Currency
    private let userCurrencies: [Currency]
    private var bag: Set<AnyCancellable> = []
    private lazy var dataLoader: ListDataLoader = setupLoader()

    init(
        sourceCurrency: Currency,
        userCurrenciesProvider: UserCurrenciesProviding,
        tokenIconURLBuilder: TokenIconURLBuilding,
        currencyMapper: CurrencyMapping,
        walletDataProvider: WalletDataProvider,
        fiatRatesProvider: FiatRatesProviding,
        coordinator: SwappingTokenListRoutable
    ) {
        self.sourceCurrency = sourceCurrency
        userCurrencies = userCurrenciesProvider.getCurrencies(blockchain: sourceCurrency.blockchain)
        self.tokenIconURLBuilder = tokenIconURLBuilder
        self.currencyMapper = currencyMapper
        self.walletDataProvider = walletDataProvider
        self.fiatRatesProvider = fiatRatesProvider
        self.coordinator = coordinator

        setupNavigationTitleView()
        setupUserItemsSection()
        bind()
        fetch()
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
        let currencies = userCurrencies.filter { sourceCurrency != $0 }

        runTask(in: self) { obj in
            var items: [SwappingTokenItemViewModel] = []

            for currency in currencies {
                let balance = await obj.getCurrencyAmount(for: currency)
                var fiatBalance: Decimal?

                if let balance {
                    fiatBalance = try? await obj.fiatRatesProvider.getFiat(for: currency, amount: balance.value)
                }

                let viewModel = obj.mapToSwappingTokenItemViewModel(
                    currency: currency,
                    balance: balance,
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
        let dataLoader = ListDataLoader(networkIds: [sourceCurrency.blockchain.networkId], exchangeable: true)
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

    func getCurrencyAmount(for currency: Currency) async -> CurrencyAmount? {
        do {
            let balance = try await walletDataProvider.getBalance(for: currency)
            return CurrencyAmount(value: balance, currency: currency)
        } catch {
            return nil
        }
    }
}
