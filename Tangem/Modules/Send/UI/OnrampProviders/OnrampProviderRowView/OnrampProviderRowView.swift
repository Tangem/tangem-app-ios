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
        .allowsHitTesting(data.isTappable)
    }

    private var content: some View {
        HStack(spacing: 12) {
            iconView

            VStack(spacing: 2) {
                topLineView

                bottomLineView
            }
            .lineLimit(1)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 14)
        .overlay { overlay }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var overlay: some View {
        if data.isSelected {
            Color.clear.overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Colors.Icon.accent, lineWidth: 1)
            }
            .padding(1)
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Colors.Icon.accent.opacity(0.15), lineWidth: 2.5)
            }
            .padding(2.5)
        }
    }

    private var iconView: some View {
        IconView(
            url: data.iconURL,
            size: CGSize(width: 36, height: 36),
            cornerRadius: 0,
            // Kingfisher shows a gray background even if it has a cached image
            forceKingfisher: false
        )
        .opacity(data.isTappable ? 1 : 0.4)
    }

    private var topLineView: some View {
        HStack(spacing: 12) {
            Text(data.name)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

            Spacer()

            if let formattedAmount = data.formattedAmount {
                Text(formattedAmount)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
            }
        }
    }

    private var bottomLineView: some View {
        HStack(spacing: 12) {
            stateView

            Spacer()

            switch data.badge {
            case .none:
                EmptyView()
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

    @ViewBuilder
    private var stateView: some View {
        switch data.state {
        case .none:
            EmptyView()
        case .available(let time):
            timeView(time: time)
        case .availableFromAmount(let text),
             .availableToAmount(let text),
             .availableForPaymentMethods(let text):
            Text(text)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
        case .unavailable(let reason):
            Text(reason)
                .style(Fonts.Regular.caption1, color: Colors.Text.warning)
        }
    }

    @ViewBuilder
    private func timeView(time: String) -> some View {
        HStack(spacing: 4) {
            Assets.speedMiniIcon.image
                .renderingMode(.template)
                .resizable()
                .frame(width: 10, height: 10)
                .foregroundColor(Colors.Icon.informative)

            Text(time)
                .style(Fonts.Regular.caption2, color: Colors.Text.tertiary)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Colors.Stroke.primary, lineWidth: 1)
        )
    }
}

#Preview {
    LazyVStack {
        ForEach([
            OnrampProviderRowViewData(
                name: "1Inch",
                paymentMethodId: "card",
                iconURL: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/express/1INCH512.png"),
                formattedAmount: "0,00453 BTC",
                state: .available(estimatedTime: "5 min"),
                badge: .bestRate,
                isSelected: true,
                action: {}
            ),
            OnrampProviderRowViewData(
                name: "Changenow",
                paymentMethodId: "card",
                iconURL: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/express/NOW512.png"),
                formattedAmount: "0,00450 BTC",
                state: .availableFromAmount(minAmount: "15 USD"),
                badge: .percent("-0.03%", signType: .negative),
                isSelected: false,
                action: {}
            ),
        ]) {
            OnrampProviderRowView(data: $0)
        }
    }
    .padding()
}
