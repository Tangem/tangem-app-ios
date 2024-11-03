//
//  OnrampSettingsView.swift
//  TangemApp
//
//  Created by Aleksei Muraveinik on 3.11.24..
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemExpress

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
            Colors.Background.action
                .cornerRadius(14, corners: .allCorners)
        )
    }
}
