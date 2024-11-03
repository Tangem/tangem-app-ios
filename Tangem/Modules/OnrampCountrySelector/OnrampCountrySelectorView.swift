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
            Colors.Icon.inactive
                .frame(width: 32, height: 4)
                .cornerRadius(2, corners: .allCorners)
                .padding(.vertical, 8)

            CustomSearchBar(
                searchText: $viewModel.searchText,
                placeholder: "Search by country",
                keyboardType: .alphabet,
                style: .translucent,
                clearButtonAction: {
                    viewModel.searchText = ""
                }
            )

            ScrollView {
                LazyVStack(alignment: .leading, spacing: .zero) {
                    ForEach(viewModel.countries, content: rowView)
                }
            }
        }
        .padding(.horizontal, 16)
        .background(
            Colors.Background.primary
                .ignoresSafeArea()
        )
    }

    @ViewBuilder
    private func rowView(country: OnrampCountry) -> some View {
        if country.onrampAvailable {
            Button {
                viewModel.onSelect(country: country)
            } label: {
                rowViewLabel(country: country)
            }
        } else {
            rowViewLabel(country: country)
                .opacity(0.4)
        }
    }

    private func rowViewLabel(country: OnrampCountry) -> some View {
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
    }
}
