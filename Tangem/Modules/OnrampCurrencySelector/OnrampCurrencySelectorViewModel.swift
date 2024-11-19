//
//  OnrampCurrencySelectorViewModel.swift
//  TangemApp
//
//  Created by Aleksei Muraveinik on 3.11.24..
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemExpress

enum OnrampCurrencySelectorState {
    case sectioned(popular: [OnrampCurrencyViewData], other: [OnrampCurrencyViewData])
    case searched([OnrampCurrencyViewData])
}

final class OnrampCurrencySelectorViewModel: Identifiable, ObservableObject {
    @Published var searchText: String = ""
    @Published private(set) var currencies: LoadingValue<OnrampCurrencySelectorState> = .loading

    private let repository: OnrampRepository
    private let dataRepository: OnrampDataRepository
    private weak var coordinator: OnrampCurrencySelectorRoutable?

    private let currenciesSubject = PassthroughSubject<[OnrampFiatCurrency], Never>()
    private var bag = Set<AnyCancellable>()

    init(
        repository: OnrampRepository,
        dataRepository: OnrampDataRepository,
        coordinator: OnrampCurrencySelectorRoutable
    ) {
        self.repository = repository
        self.dataRepository = dataRepository
        self.coordinator = coordinator

        bind()
        loadCurrencies()
    }

    func loadCurrencies() {
        currencies = .loading
        TangemFoundation.runTask(in: self) { viewModel in
            do {
                let currencies = try await viewModel.dataRepository.currencies()
                viewModel.currenciesSubject.send(currencies)
            } catch {
                await runOnMain {
                    viewModel.currencies = .failedToLoad(error: error)
                }
            }
        }
    }
}

private extension OnrampCurrencySelectorViewModel {
    func bind() {
        Publishers.CombineLatest(
            currenciesSubject,
            $searchText
        )
        .withWeakCaptureOf(self)
        .map { viewModel, data in
            let (currencies, searchText) = data
            return .loaded(
                viewModel.mapToState(
                    currencies: currencies,
                    searchText: searchText
                )
            )
        }
        .receive(on: DispatchQueue.main)
        .assign(to: \.currencies, on: self, ownership: .weak)
        .store(in: &bag)
    }

    func mapToState(
        currencies: [OnrampFiatCurrency],
        searchText: String
    ) -> OnrampCurrencySelectorState {
        if !searchText.isEmpty {
            return .searched(
                SearchUtil.search(
                    currencies,
                    in: \.identity.name,
                    for: searchText
                )
                .map(mapToCurrencyViewData)
            )
        }

        var popular = [OnrampCurrencyViewData]()
        var other = [OnrampCurrencyViewData]()

        let popularFiatCodes = dataRepository.popularFiatCodes
        for currency in currencies {
            if popularFiatCodes.contains(currency.identity.code) {
                popular.append(mapToCurrencyViewData(currency: currency))
            } else {
                other.append(mapToCurrencyViewData(currency: currency))
            }
        }

        return .sectioned(
            popular: popular,
            other: other
        )
    }

    func mapToCurrencyViewData(currency: OnrampFiatCurrency) -> OnrampCurrencyViewData {
        OnrampCurrencyViewData(
            image: currency.identity.image,
            code: currency.identity.code,
            name: currency.identity.name,
            isSelected: repository.preferenceCurrency == currency,
            action: { [weak self] in
                self?.repository.updatePreference(currency: currency)
                self?.coordinator?.dismissCurrencySelector()
            }
        )
    }
}
