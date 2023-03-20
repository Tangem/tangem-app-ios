//
//  ReceiveCurrencyView.swift
//  Tangem
//
//  Created by Sergey Balashov on 16.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct ReceiveCurrencyView: View {
    private let viewModel: ReceiveCurrencyViewModel
    private let tokenIconSize = CGSize(width: 36, height: 36)
    private var didTapChangeCurrency: () -> Void = {}

    init(viewModel: ReceiveCurrencyViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerLabels

            mainContent
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Colors.Background.primary)
        .cornerRadius(14)
    }

    private var headerLabels: some View {
        HStack(spacing: 0) {
            Text(Localization.exchangeReceiveViewHeader)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            Spacer()

            if let balanceString = viewModel.balanceString {
                Text(balanceString)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        HStack(spacing: 0) {
            currencyContent

            Spacer()

            SwappingTokenIconView(viewModel: viewModel.tokenIcon)
                .onTap(viewModel.canChangeCurrency ? didTapChangeCurrency : nil)
        }
    }

    private var currencyContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch viewModel.cryptoAmountState {
            case .loading:
                SkeletonView()
                    .frame(width: 102, height: 24)
                    .cornerRadius(6)
                    .padding(.vertical, 6)

            case .loaded:
                Text(viewModel.cryptoAmountFormatted)
                    .style(Fonts.Regular.title1, color: Colors.Text.primary1)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }

            switch viewModel.fiatAmountState {
            case .loading:
                SkeletonView()
                    .frame(width: 40, height: 13)
                    .cornerRadius(6)
            case .loaded:
                Text(viewModel.fiatAmountFormatted)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Setupable

extension ReceiveCurrencyView: Setupable {
    func didTapChangeCurrency(_ block: @escaping () -> Void) -> Self {
        map { $0.didTapChangeCurrency = block }
    }
}

struct ReceiveCurrencyView_Preview: PreviewProvider {
    static let viewModels = [
        ReceiveCurrencyViewModel(
            balance: 0.124124,
            canChangeCurrency: false,
            cryptoAmountState: .loading,
            fiatAmountState: .loading,
            tokenIcon: SwappingTokenIconViewModel(
                state: .loaded(
                    imageURL: TokenIconURLBuilderMock().iconURL(id: "polygon", size: .large),
                    symbol: "MATIC"
                )
            )
        ),
        ReceiveCurrencyViewModel(
            balance: 0.124124,
            canChangeCurrency: false,
            cryptoAmountState: .loaded(1100.46),
            fiatAmountState: .loading,
            tokenIcon: SwappingTokenIconViewModel(
                state: .loaded(
                    imageURL: TokenIconURLBuilderMock().iconURL(id: "polygon", size: .large),
                    symbol: "MATIC"
                )
            )
        ),
        ReceiveCurrencyViewModel(
            balance: 0.124124,
            canChangeCurrency: false,
            cryptoAmountState: .loading,
            fiatAmountState: .loaded(1100.46),
            tokenIcon: SwappingTokenIconViewModel(
                state: .loaded(
                    imageURL: TokenIconURLBuilderMock().iconURL(id: "polygon", size: .large),
                    symbol: "MATIC"
                )
            )
        ),
        ReceiveCurrencyViewModel(
            balance: 0.124124,
            canChangeCurrency: false,
            cryptoAmountState: .loaded(1100.46),
            fiatAmountState: .loaded(1100.46),
            tokenIcon: SwappingTokenIconViewModel(
                state: .loaded(
                    imageURL: TokenIconURLBuilderMock().iconURL(id: "polygon", size: .large),
                    symbol: "MATIC"
                )
            )
        ),
    ]

    static var previews: some View {
        ZStack {
            Colors.Background.secondary

            VStack {
                ForEach(viewModels) {
                    ReceiveCurrencyView(viewModel: $0)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
