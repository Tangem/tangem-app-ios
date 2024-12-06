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

            Text(Localization.onrampSettingsResidenceDescription)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .padding(.horizontal, 14)

            Spacer()
        }
        .padding(.horizontal, 16)
        .background(
            Colors.Background.tertiary
                .ignoresSafeArea()
        )
        .navigationBarTitle(Localization.onrampSettingsTitle, displayMode: .inline)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: viewModel.onAppear)
    }

    private var rowView: some View {
        HStack(spacing: 6) {
            Text(Localization.onrampSettingsResidence)
                .lineLimit(1)
                .style(Fonts.Regular.footnote, color: Colors.Text.secondary)

            Spacer()

            if let country = viewModel.selectedCountry?.identity {
                IconView(
                    url: country.image,
                    size: .init(bothDimensions: 20)
                )

                Text(country.name)
                    .lineLimit(1)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
            }

            Assets.chevronRightWithOffset24.image
                .resizable()
                .frame(size: .init(bothDimensions: 24))
                .foregroundColor(Colors.Icon.informative)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            Colors.Background.action
                .cornerRadiusContinuous(14)
        )
    }
}
