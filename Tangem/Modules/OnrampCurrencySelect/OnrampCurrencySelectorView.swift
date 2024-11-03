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
            Colors.Icon.inactive
                .frame(width: 32, height: 4)
                .cornerRadius(2, corners: .allCorners)
                .padding(.vertical, 8)

            CustomSearchBar(
                searchText: $viewModel.searchText,
                placeholder: "Search by currency",
                keyboardType: .alphabet,
                style: .translucent,
                clearButtonAction: {
                    viewModel.searchText = ""
                }
            )

            ScrollView {
                LazyVStack(alignment: .leading, spacing: .zero) {
                    ForEach(viewModel.sections, content: sectionView)
                }
            }
        }
        .padding(.horizontal, 16)
        .background(
            Colors.Background.primary
                .ignoresSafeArea()
        )
    }

    private func sectionView(section: OnrampCurrencySelectorViewSection) -> some View {
        LazyVStack(alignment: .leading, spacing: .zero) {
            if let title = section.title {
                Text(title)
                    .font(Fonts.Bold.footnote)
                    .foregroundColor(Colors.Text.tertiary)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
            }

            ForEach(section.items, content: rowView)
        }
    }

    @ViewBuilder
    private func rowView(currency: OnrampFiatCurrency) -> some View {
        Button {
            viewModel.onSelect(currency: currency)
        } label: {
            rowViewLabel(currency: currency)
        }
    }

    private func rowViewLabel(currency: OnrampFiatCurrency) -> some View {
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
    }
}
