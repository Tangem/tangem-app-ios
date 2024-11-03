//
//  SendCoordinatorView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: SendCoordinator

    init(coordinator: SendCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        NavigationView {
            ZStack {
                if let rootViewModel = coordinator.rootViewModel {
                    SendView(viewModel: rootViewModel, transitionService: .init())
                        .navigationLinks(links)
                }

                sheets
            }
        }
        .accentColor(Colors.Text.primary1)
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.onrampSettingsViewModel) {
                OnrampSettingsView(viewModel: $0)
            }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .bottomSheet(
                item: $coordinator.expressApproveViewModel,
                backgroundColor: Colors.Background.tertiary
            ) {
                ExpressApproveView(viewModel: $0)
            }
            .bottomSheet(
                item: $coordinator.onrampCountryViewModel,
                settings: .init(
                    backgroundColor: Colors.Background.tertiary,
                    hidingOption: .nonHideable
                )
            ) {
                OnrampCountryView(viewModel: $0)
            }
            .sheet(item: $coordinator.mailViewModel) {
                MailView(viewModel: $0)
            }
            .sheet(item: $coordinator.qrScanViewCoordinator) {
                QRScanViewCoordinatorView(coordinator: $0)
                    .edgesIgnoringSafeArea(.all)
            }
            .sheet(item: $coordinator.onrampProvidersCoordinator) {
                OnrampProvidersCoordinatorView(coordinator: $0)
            }
            .sheet(item: $coordinator.onrampCountrySelectorViewModel) {
                OnrampCountrySelectorView(viewModel: $0)
            }
            .sheet(item: $coordinator.onrampCurrencySelectViewModel) {
                OnrampCurrencySelectorView(viewModel: $0)
            }
    }
}

import Combine
import TangemExpress

protocol OnrampCountrySelectorRoutable: AnyObject {
    func dismissCountrySelector()
}

final class OnrampCountrySelectorViewModel: Identifiable, ObservableObject {
    let preferenceCountry: OnrampCountry?
    @Published var searchText: String = ""
    @Published private(set) var countries: [OnrampCountry] = []

    private let repository: OnrampRepository
    private weak var coordinator: OnrampCountrySelectorRoutable?

    init(
        repository: OnrampRepository,
        dataRepository: OnrampDataRepository,
        coordinator: OnrampCountrySelectorRoutable
    ) {
        self.repository = repository
        self.coordinator = coordinator

        preferenceCountry = repository.preferenceCountry

        let countriesPublisher = Async {
            try await dataRepository.countries()
        }

        Publishers.CombineLatest(
            countriesPublisher,
            $searchText.eraseError()
        )
        .map { items, searchText in
            SearchUtil.search(searchText, in: items, keyPath: \.identity.name)
        }
        .catch { error in
            // TODO: Handle error
            return Just([])
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$countries)
    }

    func onSelect(country: OnrampCountry) {
        repository.updatePreference(country: country)
        coordinator?.dismissCountrySelector()
    }
}

struct OnrampCountrySelectorView: View {
    @ObservedObject var viewModel: OnrampCountrySelectorViewModel

    var body: some View {
        VStack(alignment: .center, spacing: .zero) {
            Color(UIColor.iconInactive)
                .frame(width: 32, height: 4)
                .cornerRadius(2, corners: .allCorners)
                .padding(.vertical, 8)

            CustomSearchBar(
                searchText: $viewModel.searchText,
                placeholder: "Search by country",
                keyboardType: .alphabet,
                style: .translucent,
                clearButtonAction: { viewModel.searchText = "" }
            )
            .padding(.horizontal, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: .zero) {
                    ForEach(viewModel.countries, content: listItem)
                }
            }
        }
        .background(
            Colors.Background.primary.ignoresSafeArea()
        )
    }

    @ViewBuilder
    private func listItem(country: OnrampCountry) -> some View {
        if country.onrampAvailable {
            Button {
                viewModel.onSelect(country: country)
            } label: {
                row(country: country)
            }
        } else {
            row(country: country)
                .opacity(0.4)
        }
    }

    private func row(country: OnrampCountry) -> some View {
        HStack(alignment: .center, spacing: .zero) {
            if let imageURL = country.identity.image {
                IconView(
                    url: imageURL,
                    size: .init(bothDimensions: 36)
                )
                .padding(.trailing, 12)
            }

            Text(country.identity.name)
                .lineLimit(1)
                .font(Fonts.Bold.subheadline)
                .foregroundColor(Colors.Text.primary1)
                .padding(.trailing, 6)

            Spacer()

            if !country.onrampAvailable {
                Text("Unavailable")
                    .lineLimit(1)
                    .font(Fonts.Regular.caption1)
                    .foregroundColor(Colors.Text.tertiary)
            } else if country == viewModel.preferenceCountry {
                Assets.checkmark20.image
                    .resizable()
                    .frame(size: .init(bothDimensions: 24))
                    .foregroundColor(Colors.Icon.accent)
            }
        }
        .padding(.vertical, 15)
        .padding(.horizontal, 16)
    }
}

protocol OnrampSettingsRoutable: AnyObject {
    func openOnrampCountrySelector()
}

final class OnrampSettingsViewModel: ObservableObject {
    @Published private(set) var selectedCountry: OnrampCountry?

    private weak var coordinator: OnrampSettingsRoutable?

    init(repository: OnrampRepository, coordinator: OnrampSettingsRoutable) {
        self.coordinator = coordinator
        selectedCountry = repository.preferenceCountry

        repository.preferenceCountryPublisher
            .assign(to: &$selectedCountry)
    }

    func onTapResidence() {
        coordinator?.openOnrampCountrySelector()
    }
}

struct OnrampSettingsView: View {
    @ObservedObject var viewModel: OnrampSettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: viewModel.onTapResidence) {
                rowView
            }

            Text("Please select the correct country to ensure accurate payment options and services.")
                .font(Fonts.Regular.footnote)
                .foregroundColor(Colors.Text.tertiary)
                .padding(.horizontal, 14)

            Spacer()
        }
        .padding(.horizontal, 16)
        .background(
            Colors.Background.tertiary
                .ignoresSafeArea()
        )
        .navigationBarTitle("Settings", displayMode: .inline)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var rowView: some View {
        HStack(spacing: 6) {
            Text("Residence")
                .lineLimit(1)
                .font(Fonts.Regular.footnote)
                .foregroundColor(Colors.Text.secondary)

            Spacer()

            if let country = viewModel.selectedCountry?.identity {
                IconView(
                    url: country.image,
                    size: .init(bothDimensions: 20)
                )

                Text(country.name)
                    .lineLimit(1)
                    .font(Fonts.Regular.subheadline)
                    .foregroundColor(Colors.Text.primary1)
            }

            Assets.chevronRightWithOffset24.image
                .frame(size: .init(bothDimensions: 24))
                .foregroundColor(Colors.Icon.informative)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            Colors.Background.primary
                .cornerRadius(14, corners: .allCorners)
        )
    }
}

protocol OnrampCurrencySelectorRoutable: AnyObject {
    func dismissCurrencySelector()
}

final class OnrampCurrencySelectorViewModel: Identifiable, ObservableObject {
    let preferenceCurrency: OnrampFiatCurrency?
    @Published var searchText: String = ""
    @Published private(set) var popularFiats: [OnrampFiatCurrency] = []
    @Published private(set) var currencies: [OnrampFiatCurrency] = []

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

        Async {
            await dataRepository.popularFiats
        }
        .assign(to: &$popularFiats)

        let currenciesPublisher = Async {
            try await dataRepository.currencies()
        }

        Publishers.CombineLatest3(
            currenciesPublisher,
            $searchText.eraseError(),
            $popularFiats.eraseError()
        )
        .map { items, searchText, popular in
            guard !searchText.isEmpty else {
                return items.filter {
                    !popular.contains($0)
                }
            }

            return SearchUtil.search(searchText, in: items, keyPath: \.identity.name)
        }
        .catch { error in
            // TODO: Handle error
            return Just([])
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$currencies)
    }

    func onSelect(currency: OnrampFiatCurrency) {
        repository.updatePreference(currency: currency)
        coordinator?.dismissCurrencySelector()
    }
}

struct OnrampCurrencySelectorView: View {
    @ObservedObject var viewModel: OnrampCurrencySelectorViewModel

    var body: some View {
        VStack(alignment: .center, spacing: .zero) {
            Color(UIColor.iconInactive)
                .frame(width: 32, height: 4)
                .cornerRadius(2, corners: .allCorners)
                .padding(.vertical, 8)

            CustomSearchBar(
                searchText: $viewModel.searchText,
                placeholder: "Search by currency",
                keyboardType: .alphabet,
                style: .translucent,
                clearButtonAction: { viewModel.searchText = "" }
            )
            .padding(.horizontal, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: .zero) {
                    if viewModel.searchText.isEmpty {
                        if !viewModel.popularFiats.isEmpty {
                            Text("Popular Fiats")
                                .font(Fonts.Bold.footnote)
                                .foregroundColor(Colors.Text.tertiary)
                                .padding(.leading, 16)
                                .padding(.top, 12)
                                .padding(.bottom, 8)

                            ForEach(viewModel.popularFiats, content: listItem)
                        }

                        if !viewModel.currencies.isEmpty {
                            Text("Other currencies")
                                .font(Fonts.Bold.footnote)
                                .foregroundColor(Colors.Text.tertiary)
                                .padding(.leading, 16)
                                .padding(.top, 12)
                                .padding(.bottom, 8)
                        }
                    }

                    ForEach(viewModel.currencies, content: listItem)
                }
            }
        }
        .background(
            Colors.Background.primary.ignoresSafeArea()
        )
    }

    @ViewBuilder
    private func listItem(currency: OnrampFiatCurrency) -> some View {
        Button {
            viewModel.onSelect(currency: currency)
        } label: {
            row(currency: currency)
        }
    }

    private func row(currency: OnrampFiatCurrency) -> some View {
        HStack(alignment: .center, spacing: .zero) {
            if let imageURL = currency.identity.image {
                IconView(
                    url: imageURL,
                    size: .init(bothDimensions: 36)
                )
                .padding(.trailing, 12)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(currency.identity.code)
                    .font(Fonts.Bold.subheadline)
                    .foregroundColor(Colors.Text.primary1)

                Text(currency.identity.name)
                    .lineLimit(1)
                    .font(Fonts.Regular.caption1)
                    .foregroundColor(Colors.Text.tertiary)
            }
            .padding(.trailing, 6)

            Spacer()

            if currency == viewModel.preferenceCurrency {
                Assets.checkmark20.image
                    .resizable()
                    .frame(size: .init(bothDimensions: 24))
                    .foregroundColor(Colors.Icon.accent)
            }
        }
        .padding(.vertical, 15)
        .padding(.horizontal, 16)
    }
}

func Async<T>(_ operation: @escaping () async throws -> T) -> AnyPublisher<T, Error> {
    Future { promise in
        Task {
            do {
                let result = try await operation()
                promise(.success(result))
            } catch {
                promise(.failure(error))
            }
        }
    }
    .eraseToAnyPublisher()
}

func Async<T>(_ operation: @escaping () async -> T) -> AnyPublisher<T, Never> {
    Future { promise in
        Task {
            let result = await operation()
            promise(.success(result))
        }
    }
    .eraseToAnyPublisher()
}

enum SearchUtil<T> {
    static func search(_ searchText: String, in items: [T], keyPath: KeyPath<T, String>) -> [T] {
        if searchText.isEmpty {
            return items
        }

        return items
            .filter { item in
                item[keyPath: keyPath]
                    .lowercased()
                    .contains(searchText.lowercased())
            }
            .sorted { item, _ in
                item[keyPath: keyPath]
                    .split(separator: " ")
                    .contains { $0.starts(with: searchText) }
            }
    }
}
