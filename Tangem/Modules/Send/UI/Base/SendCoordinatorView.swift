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
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                SendView(viewModel: rootViewModel, transitionService: .init())
                    .navigationLinks(links)
            }

            sheets
        }
    }

    @ViewBuilder
    private var links: some View {
        EmptyView()
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
