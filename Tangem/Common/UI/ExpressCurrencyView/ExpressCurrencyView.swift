//
//  ExpressCurrencyView.swift
//  Tangem
//
//  Created by Sergey Balashov on 15.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct ExpressCurrencyView<Content: View>: View {
    @ObservedObject private var viewModel: ExpressCurrencyViewModel
    private let content: () -> Content

    private let imageSize = CGSize(width: 36, height: 36)
    // With 2 padding in the all edges
    private let tokenIconSize = CGSize(width: 40, height: 40)
    private let chevronIconSize = CGSize(width: 9, height: 9)
    private var didTapChangeCurrency: () -> Void = {}
    private var didTapNetworkFeeInfoButton: ((ExpressCurrencyViewModel.PriceChangeState) -> Void)?

    @State private var symbolSize: CGSize = .zero

    init(viewModel: ExpressCurrencyViewModel, content: @escaping () -> Content) {
        self.viewModel = viewModel
        self.content = content
    }

    var body: some View {
        VStack(spacing: 6) {
            topContent

            mainContent

            bottomContent
        }
    }

    var topContent: some View {
        HStack(spacing: 0) {
            switch viewModel.titleState {
            case .text(let title):
                Text(title)
                    .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
            case .insufficientFunds:
                Text(Localization.swappingInsufficientFunds)
                    .style(Fonts.Regular.caption1, color: Colors.Text.warning)
            case .error(let text):
                // Use for generic error
                Text(text)
                    .style(Fonts.Regular.caption1, color: Colors.Text.warning)
            }

            Spacer()

            switch viewModel.balanceState {
            case .idle:
                EmptyView()
            case .loading:
                SkeletonView()
                    .frame(width: 72, height: 12)
                    .cornerRadius(3)
                    .padding(.vertical, 2)
            case .notAvailable:
                Text(Localization.swappingTokenNotAvailable)
                    .style(Fonts.Regular.footnote, color: Colors.Text.disabled)
            case .formatted(let value):
                SensitiveText(builder: Localization.commonBalance, sensitive: value)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        HStack(alignment: .top, spacing: 0) {
            content()

            Spacer()

            Button(action: { didTapChangeCurrency() }) {
                ZStack(alignment: .trailing) {
                    iconContent
                        .padding(.all, 2)
                        // Chevron's space
                        .padding(.trailing, 12)

                    Assets.chevronDownMini.image
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(Colors.Icon.informative)
                        .frame(size: chevronIconSize)
                        // View have to keep size of the view same for both cases
                        .opacity(viewModel.canChangeCurrency ? 1 : 0)
                }
            }
            .disabled(!viewModel.canChangeCurrency)
        }
    }

    @ViewBuilder
    private var bottomContent: some View {
        HStack(spacing: 0) {
            HStack(spacing: 4) {
                LoadableTextView(
                    state: viewModel.fiatAmountState,
                    font: Fonts.Regular.footnote,
                    textColor: Colors.Text.tertiary,
                    loaderSize: CGSize(width: 70, height: 12),
                    lineLimit: 1,
                    isSensitiveText: false
                )

                infoButton
            }

            Spacer()

            LoadableTextView(
                state: viewModel.symbolState,
                font: Fonts.Bold.footnote,
                textColor: Colors.Text.primary1,
                loaderSize: CGSize(width: 30, height: 14),
                lineLimit: 1,
                isSensitiveText: false
            )
            .readGeometry(\.frame.size, bindTo: $symbolSize)
            // Chevron's space
            .padding(.trailing, 12)
            .offset(x: -tokenIconSize.width / 2 + symbolSize.width / 2)
        }
    }

    @ViewBuilder
    private var infoButton: some View {
        if let priceChangeState = viewModel.priceChangeState, let didTapNetworkFeeInfoButton {
            Button(action: { didTapNetworkFeeInfoButton(priceChangeState) }) {
                switch priceChangeState {
                case .info:
                    infoButtonIcon
                        .foregroundColor(Colors.Icon.informative)
                case .percent(let message):
                    HStack(spacing: 2) {
                        Text(message)
                            .style(Fonts.Regular.footnote, color: Colors.Text.attention)

                        infoButtonIcon
                            .foregroundColor(Colors.Icon.attention)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var infoButtonIcon: some View {
        Assets.infoIconMini.image
            .renderingMode(.template)
            .resizable()
            .frame(width: 16, height: 16)
    }

    @ViewBuilder
    private var iconContent: some View {
        switch viewModel.tokenIconState {
        case .loading:
            SkeletonView()
                .frame(size: imageSize)
                .cornerRadius(imageSize.height / 2)
        case .notAvailable:
            Assets.emptyTokenList.image
                .renderingMode(.template)
                .resizable()
                .foregroundColor(Colors.Icon.inactive)
                .frame(size: imageSize)
        case .icon(let tokenIconInfo):
            TokenIcon(tokenIconInfo: tokenIconInfo, size: imageSize)
        }
    }
}

// MARK: - Setupable

extension ExpressCurrencyView: Setupable {
    func didTapChangeCurrency(_ block: @escaping () -> Void) -> Self {
        map { $0.didTapChangeCurrency = block }
    }

    func didTapNetworkFeeInfoButton(_ block: @escaping (ExpressCurrencyViewModel.PriceChangeState) -> Void) -> Self {
        map { $0.didTapNetworkFeeInfoButton = block }
    }
}

struct ExpressCurrencyView_Preview: PreviewProvider {
    static let viewModels = [
        ExpressCurrencyViewModel(
            titleState: .text(Localization.swappingToTitle),
            balanceState: .loading,
            fiatAmountState: .loading,
            tokenIconState: .icon(TokenIconInfoBuilder().build(from: .blockchain(.init(.ethereum(testnet: false), derivationPath: nil)), isCustom: false)),
            symbolState: .loaded(text: "ETH"),
            canChangeCurrency: false
        ),
        ExpressCurrencyViewModel(
            titleState: .text(Localization.swappingToTitle),
            balanceState: .formatted("0.0058"),
            fiatAmountState: .loading,
            tokenIconState: .icon(TokenIconInfoBuilder().build(from: .blockchain(.init(.cardano(extended: false), derivationPath: nil)), isCustom: false)),
            symbolState: .loaded(text: "ADA"),
            canChangeCurrency: false
        ),
        ExpressCurrencyViewModel(
            titleState: .text(Localization.swappingToTitle),
            balanceState: .formatted("0.0058"),
            fiatAmountState: .loading,
            tokenIconState: .icon(TokenIconInfoBuilder().build(from: .blockchain(.init(.cardano(extended: false), derivationPath: nil)), isCustom: false)),
            symbolState: .loaded(text: "MATIC"),
            canChangeCurrency: true
        ),
        ExpressCurrencyViewModel(
            titleState: .text(Localization.swappingToTitle),
            balanceState: .formatted("0.0058"),
            fiatAmountState: .loaded(text: "1100.46"),
            tokenIconState: .icon(TokenIconInfoBuilder().build(from: .blockchain(.init(.polygon(testnet: false), derivationPath: nil)), isCustom: false)),
            symbolState: .loaded(text: "MATIC"),
            canChangeCurrency: true
        ),
        ExpressCurrencyViewModel(
            titleState: .text(Localization.swappingToTitle),
            balanceState: .formatted("0.0058"),
            fiatAmountState: .loaded(text: "2100.46 $"),
            tokenIconState: .icon(TokenIconInfoBuilder().build(from: .token(.tetherMock, .init(.polygon(testnet: false), derivationPath: nil)), isCustom: false)),
            symbolState: .loaded(text: "USDT"),
            canChangeCurrency: true
        ),
        ExpressCurrencyViewModel(
            titleState: .text(Localization.swappingToTitle),
            balanceState: .formatted("0.0058"),
            fiatAmountState: .loaded(text: "2100.46 $"),
            priceChangeState: .percent("-24.3 %"),
            tokenIconState: .icon(TokenIconInfoBuilder().build(from: .token(.tetherMock, .init(.polygon(testnet: false), derivationPath: nil)), isCustom: false)),
            symbolState: .loaded(text: "USDT"),
            canChangeCurrency: true
        ),
    ]

    static var previews: some View {
        ZStack {
            Colors.Background.secondary

            VStack {
                ForEach(viewModels) { viewModel in
                    GroupedSection(viewModel) { viewModel in
                        ExpressCurrencyView(viewModel: viewModel) {
                            LoadableTextView(
                                state: .random() ? .loading : .loaded(text: "1100.46"),
                                font: Fonts.Regular.title1,
                                textColor: Colors.Text.primary1,
                                loaderSize: CGSize(width: 102, height: 24)
                            )
                        }
                    }
                    .innerContentPadding(12)
                    .interItemSpacing(10)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
