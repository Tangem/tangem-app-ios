//
//  OnrampProviderRowView.swift
//  TangemApp
//
//  Created by Sergey Balashov on 25.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnrampProviderRowView: View {
    let data: OnrampProviderRowViewData

    var body: some View {
        Button(action: data.action) {
            content
        }
        .buttonStyle(.plain)
    }

    private var content: some View {
        HStack(spacing: 12) {
            iconView

            VStack(spacing: 2) {
                topLineView

                bottomLineView
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 14)
        .background(Colors.Background.primary)
        .cornerRadiusContinuous(14)
        .background {
            if data.isSelected {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Colors.Icon.accent, lineWidth: 1)
            }
        }
        .padding(.all, 1)
        .background {
            if data.isSelected {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Colors.Icon.accent.opacity(0.15), lineWidth: 2.5)
            }
        }
        .padding(.all, 2.5)
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

    private var topLineView: some View {
        HStack(spacing: 12) {
            Text(data.name)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

            Spacer()

            Text(data.formattedAmount)
                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
        }
    }

    private var bottomLineView: some View {
        HStack(spacing: 12) {
            Spacer()

            switch data.badge {
            case .percent(let text, let signType):
                Text(text)
                    .style(Fonts.Regular.subheadline, color: signType.textColor)
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
}

#Preview {
    OnrampProviderRowView(
        data: OnrampProviderRowViewData(
            id: "1inch",
            name: "1Inch",
            iconURL: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/express/1INCH512.png"),
            formattedAmount: "0,00453 BTC",
            badge: .bestRate,
            isSelected: true,
            action: {}
        )
    )
    .padding()
}
