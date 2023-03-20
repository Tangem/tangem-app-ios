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

                    tokenInfoView
                }

                Spacer()

                currencyView
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
    }

    private var tokenInfoView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(viewModel.name)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

            Text(viewModel.symbol)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
        }
        .lineLimit(1)
    }

    private var currencyView: some View {
        VStack(alignment: .trailing, spacing: 2) {
            if let fiatBalanceFormatted = viewModel.fiatBalanceFormatted {
                Text(fiatBalanceFormatted)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
            }

            if let balanceFormatted = viewModel.balanceFormatted {
                Text(balanceFormatted)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }
        }
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
