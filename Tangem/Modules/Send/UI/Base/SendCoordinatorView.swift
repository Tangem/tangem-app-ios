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
    }
}

import Combine
import TangemExpress

protocol OnrampCountrySelectorRoutable: AnyObject {
    func dismissCountrySelector()
}

final class OnrampCountrySelectorViewModel: Identifiable, ObservableObject {
    @Published var searchText: String = ""
    @Published private(set) var countries: [OnrampCountry] = []
    @Published private(set) var preferenceCountry: OnrampCountry?

    private let loadedCountries = CurrentValueSubject<[OnrampCountry], Never>([])

    private let repository: OnrampRepository
    private let dataRepository: OnrampDataRepository
    private weak var coordinator: OnrampCountrySelectorRoutable?

    init(
        repository: OnrampRepository,
        dataRepository: OnrampDataRepository,
        coordinator: OnrampCountrySelectorRoutable
    ) {
        self.repository = repository
        self.dataRepository = dataRepository
        self.coordinator = coordinator

        preferenceCountry = repository.preferenceCountry

        repository.preferenceCountryPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$preferenceCountry)

        Publishers.CombineLatest(
            loadedCountries,
            $searchText
        )
        .map { items, searchText in
            items.filter {
                $0.identity.name.starts(with: searchText)
            }
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$countries)

        Task {
            do {
                let countries = try await dataRepository.countries()
                self.loadedCountries.send(countries)
            } catch {
                // TODO: Handle error
            }
        }
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

    private func listItem(country: OnrampCountry) -> some View {
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
                .truncationMode(.tail)
                .font(Fonts.Bold.subheadline)
                .foregroundColor(Colors.Text.primary1)
                .padding(.trailing, 6)

            Spacer()

            if !country.onrampAvailable {
                Text("Unavailable")
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
        .if(country.onrampAvailable) { view in
            view.onTapGesture {
                viewModel.onSelect(country: country)
            }
        } else: { view in
            view.opacity(0.4)
        }
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

        repository.preferenceCountryPublisher.assign(to: &$selectedCountry)
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
                .font(Fonts.Regular.footnote)
                .foregroundColor(Colors.Text.secondary)

            Spacer()

            if let country = viewModel.selectedCountry?.identity {
                IconView(
                    url: country.image,
                    size: .init(bothDimensions: 20)
                )

                Text(country.name)
                    .font(Fonts.Regular.subheadline)
                    .foregroundColor(Colors.Text.primary1)
                    .lineLimit(1)
                    .truncationMode(.tail)
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
