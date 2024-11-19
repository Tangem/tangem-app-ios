//
//  OnrampCountrySelectorViewModel.swift
//  TangemApp
//
//  Created by Aleksei Muraveinik on 3.11.24..
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemExpress

final class OnrampCountrySelectorViewModel: Identifiable, ObservableObject {
    @Published var searchText: String = ""
    @Published private(set) var countries: LoadingValue<[OnrampCountryViewData]> = .loading

    private let repository: OnrampRepository
    private let dataRepository: OnrampDataRepository
    private weak var coordinator: OnrampCountrySelectorRoutable?

    private let countriesSubject = PassthroughSubject<[OnrampCountry], Never>()
    private var bag = Set<AnyCancellable>()

    init(
        repository: OnrampRepository,
        dataRepository: OnrampDataRepository,
        coordinator: OnrampCountrySelectorRoutable
    ) {
        self.repository = repository
        self.dataRepository = dataRepository
        self.coordinator = coordinator

        bind()
        loadCountries()
    }

    func loadCountries() {
        countries = .loading
        TangemFoundation.runTask(in: self) { viewModel in
            do {
                let countries = try await viewModel.dataRepository.countries()
                viewModel.countriesSubject.send(countries)
            } catch {
                await runOnMain {
                    viewModel.countries = .failedToLoad(error: error)
                }
            }
        }
    }
}

private extension OnrampCountrySelectorViewModel {
    func bind() {
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
        .assign(to: \.countries, on: self, ownership: .weak)
        .store(in: &bag)
    }

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
                    self?.updatePreference(country: country)
                    self?.coordinator?.dismissCountrySelector()
                }
            )
        }
    }

    func updatePreference(country: OnrampCountry) {
        // We have to save the currency in repository
        // if we don't have one
        if repository.preferenceCurrency == nil {
            repository.updatePreference(country: country, currency: country.currency)
        } else {
            repository.updatePreference(country: country)
        }
    }
}
