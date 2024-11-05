//
//  OnrampCurrencyView.swift
//  TangemApp
//
//  Created by Aleksei Muraveinik on 5.11.24..
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnrampCurrencyView: View {
    let data: OnrampCurrencyViewData

    var body: some View {
        Button(action: data.action) {
            labelView
        }
    }

    private var labelView: some View {
        HStack(alignment: .center, spacing: .zero) {
            IconView(
                url: data.image,
                size: .init(bothDimensions: 36)
            )
            .padding(.trailing, 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(data.code)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                Text(data.name)
                    .lineLimit(1)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            }
            .padding(.trailing, 6)

            Spacer()

            if data.isSelected {
                Assets.checkmark20.image
                    .resizable()
                    .frame(size: .init(bothDimensions: 24))
                    .foregroundColor(Colors.Icon.accent)
            }
        }
        .padding(.vertical, 14)
    }
}
