//
//  OnrampProvidersCompactProviderView.swift
//  TangemApp
//
//  Created by Sergey Balashov on 31.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnrampProvidersCompactProviderView: View {
    let data: OnrampProvidersCompactProviderViewData

    var body: some View {
        Button(action: data.action) {
            content
        }
        .buttonStyle(.plain)
    }

    private var content: some View {
        HStack {
            IconView(
                url: data.iconURL,
                size: CGSize(width: 36, height: 36),
                cornerRadius: 0,
                // Kingfisher shows a gray background even if it has a cached image
                forceKingfisher: false
            )

            titleView

            Spacer()

            badgeView
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }

    private var titleView: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text(Localization.onrampPayWith)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
                Text(data.paymentMethodName)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
            }

            Text("\(Localization.onrampVia) \(data.providerName)")
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
        }
        .lineLimit(1)
    }

    @ViewBuilder
    private var badgeView: some View {
        switch data.badge {
        case .none:
            EmptyView()
        case .bestRate:
            Text(Localization.expressProviderBestRate)
                .style(Fonts.Bold.caption2, color: Colors.Text.primary2)
                .padding(.vertical, 2)
                .padding(.horizontal, 6)
                .background(Colors.Icon.accent)
                .cornerRadiusContinuous(6)
        }
    }
}
