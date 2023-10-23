//
//  SwappingTokenItemView.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct SwappingTokenItemView: View {
    static let iconSize = CGSize(width: 40, height: 40)
    static let horizontalInteritemSpacing: CGFloat = 12

    private let viewModel: SwappingTokenItemViewModel

    init(viewModel: SwappingTokenItemViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Button(action: viewModel.itemDidTap) {
            HStack(spacing: 0) {
                HStack(spacing: Self.horizontalInteritemSpacing) {
                    IconView(url: viewModel.iconURL, size: Self.iconSize)

                    infoView
                }
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var infoView: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: .zero) {
                Text(viewModel.name)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                Spacer(minLength: 4)

                if let fiatBalanceFormatted = viewModel.fiatBalanceFormatted {
                    SensitiveText(fiatBalanceFormatted)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
                }
            }

            HStack(spacing: .zero) {
                Text(viewModel.symbol)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                Spacer(minLength: 4)

                if let balanceFormatted = viewModel.balanceFormatted {
                    SensitiveText(balanceFormatted)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                }
            }
        }
        .lineLimit(1)
    }
}

struct SwappingTokenItemView_Previews: PreviewProvider {
    static let viewModels = [
        SwappingTokenItemViewModel(
            tokenId: "Bitcoin",
            iconURL: nil,
            name: "Bitcoin",
            symbol: "BTC",
            balance: CurrencyAmount(value: 3.543, currency: .mock),
            fiatBalance: 1.23415 * 16345,
            itemDidTap: {}
        ), SwappingTokenItemViewModel(
            tokenId: "Ethereum",
            iconURL: nil,
            name: "Ethereum",
            symbol: "ETH",
            balance: CurrencyAmount(value: 3.543, currency: .mock),
            fiatBalance: 3.543 * 1341,
            itemDidTap: {}
        ),
    ]

    static var previews: some View {
        ZStack {
            Colors.Background.secondary

            GroupedSection(viewModels) {
                SwappingTokenItemView(viewModel: $0)
            }
            .separatorPadding(68)
        }
    }
}
