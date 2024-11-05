//
//  OnrampCountrySelectorViewModel.swift
//  TangemApp
//
//  Created by Aleksei Muraveinik on 3.11.24..
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

final class OnrampCountrySelectorViewModel: Identifiable, ObservableObject {
    @Published var searchText: String = ""
    @Published private(set) var countries: LoadingValue<[OnrampCountryViewData]> = .loading

    private let repository: OnrampRepository
    private let dataRepository: OnrampDataRepository
    private weak var coordinator: OnrampCountrySelectorRoutable?

    private let countriesSubject = PassthroughSubject<[OnrampCountry], Never>()

    init(
        repository: OnrampRepository,
        dataRepository: OnrampDataRepository,
        coordinator: OnrampCountrySelectorRoutable
    ) {
        self.repository = repository
        self.dataRepository = dataRepository
        self.coordinator = coordinator

        Publishers.CombineLatest(
            countriesSubject,
            $searchText
        )
        .withWeakCaptureOf(self)
        .map { viewModel, data in
            let (countries, searchText) = data
            return .loaded(
                viewModel.mapToCountriesViewData(
                    countries: countries,
                    searchText: searchText
                )
            )
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$countries)

        loadCountries()
    }

    func loadCountries() {
        countries = .loading
        Task {
            do {
                let countries = try await dataRepository.countries()
                countriesSubject.send(countries)
            } catch {
                countries = .failedToLoad(error: error)
            }
        }
    }
}

private extension OnrampCountrySelectorViewModel {
    func mapToCountriesViewData(countries: [OnrampCountry], searchText: String) -> [OnrampCountryViewData] {
        SearchUtil.search(
            countries,
            in: \.identity.name,
            for: searchText
        )
        .map { country in
            OnrampCountryViewData(
                image: country.identity.image,
                name: country.identity.name,
                isAvailable: country.onrampAvailable,
                isSelected: repository.preferenceCountry == country,
                action: { [weak self] in
                    self?.repository.updatePreference(country: country)
                    self?.coordinator?.dismissCountrySelector()
                }
            )
        }
    }
}
