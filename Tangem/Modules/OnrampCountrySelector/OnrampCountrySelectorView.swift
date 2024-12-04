//
//  OnrampCountrySelectorView.swift
//  TangemApp
//
//  Created by Aleksei Muraveinik on 3.11.24..
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemExpress

struct OnrampCountrySelectorView: View {
    @ObservedObject var viewModel: OnrampCountrySelectorViewModel

    var body: some View {
        VStack(alignment: .center, spacing: .zero) {
            GrabberViewFactory().makeSwiftUIView()

            CustomSearchBar(
                searchText: $viewModel.searchText,
                placeholder: Localization.onrampCountrySearch,
                keyboardType: .alphabet,
                style: .translucent,
                clearButtonAction: {
                    viewModel.searchText = ""
                }
            )
            .padding(.horizontal, 16)

            contentView
        }
        .background(Colors.Background.primary.ignoresSafeArea())
    }
}

private extension OnrampCountrySelectorView {
    @ViewBuilder
    var contentView: some View {
        switch viewModel.countries {
        case .loading:
            skeletonsView
                .transition(.opacityLinear())
        case .loaded(let data):
            countriesView(data: data)
                .transition(.opacityLinear())
        case .failedToLoad:
            failedToLoadView
                .transition(.opacityLinear())
        }
    }

    @ViewBuilder
    var failedToLoadView: some View {
        Spacer()

        UnableToLoadDataView(
            isButtonBusy: false,
            retryButtonAction: viewModel.loadCountries
        )

        Spacer()
    }

    var skeletonsView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: .zero) {
                ForEach(0 ..< 20) { _ in
                    OnrampCountrySkeletonView()
                }
            }
            .padding(.horizontal, 16)
        }
    }

    func countriesView(data: [OnrampCountryViewData]) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: .zero) {
                ForEach(data) { data in
                    OnrampCountryView(data: data)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
