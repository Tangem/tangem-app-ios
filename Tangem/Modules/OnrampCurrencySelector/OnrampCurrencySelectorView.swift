//
//  OnrampCurrencySelectorView.swift
//  TangemApp
//
//  Created by Aleksei Muraveinik on 3.11.24..
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemExpress

struct OnrampCurrencySelectorView: View {
    @ObservedObject var viewModel: OnrampCurrencySelectorViewModel

    var body: some View {
        VStack(alignment: .center, spacing: .zero) {
            GrabberViewFactory().makeSwiftUIView()

            CustomSearchBar(
                searchText: $viewModel.searchText,
                placeholder: Localization.onrampCurrencySearch,
                keyboardType: .alphabet,
                style: .translucent,
                clearButtonAction: {
                    viewModel.searchText = ""
                }
            )
            .padding(.horizontal, 16)

            contentView
        }
        .background(
            Colors.Background.primary
                .ignoresSafeArea()
        )
    }
}

private extension OnrampCurrencySelectorView {
    @ViewBuilder
    var contentView: some View {
        switch viewModel.currencies {
        case .loading:
            skeletonsView
                .transition(.opacityLinear())
        case .loaded(let currencies):
            sectionsView(for: currencies)
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
            retryButtonAction: viewModel.loadCurrencies
        )

        Spacer()
    }

    var skeletonsView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: .zero) {
                sectionViewTitle(Localization.onrampCurrencyPopular)
                ForEach(0 ..< 6) { _ in
                    OnrampCurrencySkeletonView()
                }

                sectionViewTitle(Localization.onrampCurrencyOther)
                ForEach(0 ..< 20) { _ in
                    OnrampCurrencySkeletonView()
                }
            }
            .padding(.horizontal, 16)
        }
    }

    func sectionsView(for state: OnrampCurrencySelectorState) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: .zero) {
                switch state {
                case .searched(let searched):
                    ForEach(searched) { data in
                        OnrampCurrencyView(data: data)
                    }

                case .sectioned(let popular, let other):
                    sectionViewTitle(Localization.onrampCurrencyPopular)
                    ForEach(popular) { data in
                        OnrampCurrencyView(data: data)
                    }

                    sectionViewTitle(Localization.onrampCurrencyOther)
                    ForEach(other) { data in
                        OnrampCurrencyView(data: data)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    func sectionViewTitle(_ title: String) -> some View {
        Text(title)
            .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
            .padding(.top, 12)
            .padding(.bottom, 8)
    }
}
