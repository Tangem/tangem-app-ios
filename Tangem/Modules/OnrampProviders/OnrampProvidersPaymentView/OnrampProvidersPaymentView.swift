//
//  OnrampProvidersPaymentView.swift
//  TangemApp
//
//  Created by Sergey Balashov on 25.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnrampProvidersPaymentView: View {
    let data: OnrampProvidersPaymentViewData

    var body: some View {
        Button(action: data.action) {
            content
        }
        .buttonStyle(.plain)
    }

    private var content: some View {
        HStack(spacing: 12) {
            iconView

            titleView

            Spacer()

            chevronView
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 14)
        .overlay { overlay }
        .contentShape(Rectangle())
    }

    private var iconView: some View {
        IconView(
            url: data.iconURL,
            size: CGSize(width: 36, height: 36),
            cornerRadius: 0,
            // Kingfisher shows a gray background even if it has a cached image
            forceKingfisher: false
        )
    }

    private var titleView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Localization.onrampPayWith)
                .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)

            Text(data.name)
                .style(Fonts.Bold.caption1, color: Colors.Text.primary1)
        }
        .lineLimit(1)
    }

    private var chevronView: some View {
        Assets.chevron.image
            .renderingMode(.template)
            .foregroundStyle(Colors.Icon.informative)
    }

    @ViewBuilder
    private var overlay: some View {
        Color.clear.overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Colors.Stroke.primary, lineWidth: 1)
        }
        .padding(1)
    }
}
