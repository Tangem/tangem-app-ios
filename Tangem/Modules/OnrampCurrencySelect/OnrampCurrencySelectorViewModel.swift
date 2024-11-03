//
//  OnrampCurrencySelectorViewModel.swift
//  TangemApp
//
//  Created by Aleksei Muraveinik on 3.11.24..
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

struct OnrampCurrencySelectorViewSection: Identifiable {
    let title: String?
    let items: [OnrampFiatCurrency]

    var id: String? { title }
}

final class OnrampCurrencySelectorViewModel: Identifiable, ObservableObject {
    let preferenceCurrency: OnrampFiatCurrency?
    @Published var searchText: String = ""
    @Published private(set) var sections: [OnrampCurrencySelectorViewSection] = []

    private let repository: OnrampRepository
    private weak var coordinator: OnrampCurrencySelectorRoutable?

    init(
        repository: OnrampRepository,
        dataRepository: OnrampDataRepository,
        coordinator: OnrampCurrencySelectorRoutable
    ) {
        self.repository = repository
        self.coordinator = coordinator

        preferenceCurrency = repository.preferenceCurrency

        Publishers.CombineLatest3(
            dataRepository.currenciesPublisher,
            dataRepository.popularFiatsPublisher,
            $searchText.eraseError()
        )
        .map(mapToSections)
        .catch { error in
            // TODO: Handle error
            return Just([])
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$sections)
    }

    func onSelect(currency: OnrampFiatCurrency) {
        repository.updatePreference(currency: currency)
        coordinator?.dismissCurrencySelector()
    }
}

private func mapToSections(
    allCurrencies: [OnrampFiatCurrency],
    popularCurrencies: [OnrampFiatCurrency],
    searchText: String
) -> [OnrampCurrencySelectorViewSection] {
    if !searchText.isEmpty {
        return [
            OnrampCurrencySelectorViewSection(
                title: nil,
                items: SearchUtil.search(
                    allCurrencies,
                    in: \.identity.name,
                    for: searchText
                )
            ),
        ]
    }

    return [
        OnrampCurrencySelectorViewSection(
            title: "Popular Fiats",
            items: popularCurrencies
        ),
        OnrampCurrencySelectorViewSection(
            title: "Other currencies",
            items: allCurrencies.filter {
                !popularCurrencies.contains($0)
            }
        ),
    ]
}
