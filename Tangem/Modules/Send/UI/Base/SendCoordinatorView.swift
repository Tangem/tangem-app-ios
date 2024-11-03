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

enum SearchUtil<T> {
    static func search(_ items: [T], in keyPath: KeyPath<T, String>, for searchText: String) -> [T] {
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
