//
//  ReceiveCurrencyView.swift
//  Tangem
//
//  Created by Sergey Balashov on 16.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct ReceiveCurrencyView: View {
    @ObservedObject private var viewModel: ReceiveCurrencyViewModel
    private var didTapChangeCurrency: () -> Void = {}
    private var didTapNetworkFeeInfoButton: ((_ isBigLoss: Bool) -> Void)?

    init(viewModel: ReceiveCurrencyViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ExpressCurrencyView(viewModel: viewModel.expressCurrencyViewModel) {
            LoadableTextView(
                state: viewModel.cryptoAmountState,
                font: Fonts.Regular.title1,
                textColor: Colors.Text.primary1,
                loaderSize: CGSize(width: 102, height: 24),
                prefix: "~"
            )
        }
        .didTapChangeCurrency(didTapChangeCurrency)
        .didTapNetworkFeeInfoButton { type in
            switch type {
            case .info:
                didTapNetworkFeeInfoButton?(false)
            case .percent:
                didTapNetworkFeeInfoButton?(true)
            }
        }
    }
}

// MARK: - Setupable

extension ReceiveCurrencyView: Setupable {
    func didTapChangeCurrency(_ block: @escaping () -> Void) -> Self {
        map { $0.didTapChangeCurrency = block }
    }

    func didTapNetworkFeeInfoButton(_ block: @escaping (_ isBigLoss: Bool) -> Void) -> Self {
        map { $0.didTapNetworkFeeInfoButton = block }
    }
}

struct ReceiveCurrencyView_Preview: PreviewProvider {
    static let viewModels = [
        ReceiveCurrencyViewModel(
            expressCurrencyViewModel: .init(
                titleState: .text(Localization.swappingToTitle),
                balanceState: .loading,
                fiatAmountState: .loading,
                tokenIconState: .icon(TokenIconInfoBuilder().build(from: .blockchain(.init(.ethereum(testnet: false), derivationPath: nil)), isCustom: false)),
                symbolState: .loaded(text: "ETH"),
                canChangeCurrency: false
            ),
            cryptoAmountState: .loading
        ),
        ReceiveCurrencyViewModel(
            expressCurrencyViewModel: .init(
                titleState: .text(Localization.swappingToTitle),
                balanceState: .formatted("0.0058"),
                fiatAmountState: .loading,
                tokenIconState: .icon(TokenIconInfoBuilder().build(from: .blockchain(.init(.cardano(extended: false), derivationPath: nil)), isCustom: false)),
                symbolState: .loaded(text: "ADA"),
                canChangeCurrency: false
            ),
            cryptoAmountState: .loading
        ),
        ReceiveCurrencyViewModel(
            expressCurrencyViewModel: .init(
                titleState: .text(Localization.swappingToTitle),
                balanceState: .formatted("0.0058"),
                fiatAmountState: .loading,
                tokenIconState: .icon(TokenIconInfoBuilder().build(from: .blockchain(.init(.polygon(testnet: false), derivationPath: nil)), isCustom: false)),
                symbolState: .loaded(text: "MATIC"),
                canChangeCurrency: true
            ),
            cryptoAmountState: .loaded(text: "1100.46")
        ),
        ReceiveCurrencyViewModel(
            expressCurrencyViewModel: .init(
                titleState: .text(Localization.swappingToTitle),
                balanceState: .formatted("0.0058"),
                fiatAmountState: .loaded(text: "1100.46"),
                tokenIconState: .icon(TokenIconInfoBuilder().build(from: .blockchain(.init(.polygon(testnet: false), derivationPath: nil)), isCustom: false)),
                symbolState: .loaded(text: "MATIC"),
                canChangeCurrency: true
            ),
            cryptoAmountState: .loading
        ),
        ReceiveCurrencyViewModel(
            expressCurrencyViewModel: .init(
                titleState: .text(Localization.swappingToTitle),
                balanceState: .formatted("0.0058"),
                fiatAmountState: .loaded(text: "2100.46 $"),
                tokenIconState: .icon(TokenIconInfoBuilder().build(from: .token(.tetherMock, .init(.polygon(testnet: false), derivationPath: nil)), isCustom: false)),
                symbolState: .loaded(text: "USDT"),
                canChangeCurrency: true
            ),
            cryptoAmountState: .loaded(text: "1100.46")
        ),
        ReceiveCurrencyViewModel(
            expressCurrencyViewModel: .init(
                titleState: .text(Localization.swappingToTitle),
                balanceState: .formatted("0.0058"),
                fiatAmountState: .loaded(text: "2100.46 $"),
                priceChangeState: .percent("-24.3 %"),
                tokenIconState: .icon(TokenIconInfoBuilder().build(from: .token(.tetherMock, .init(.polygon(testnet: false), derivationPath: nil)), isCustom: false)),
                symbolState: .loaded(text: "USDT"),
                canChangeCurrency: true
            ),
            cryptoAmountState: .loaded(text: "1100.46")
        ),
    ]

    static var previews: some View {
        ZStack {
            Colors.Background.secondary

            VStack {
                ForEach(viewModels) { viewModel in
                    GroupedSection(viewModel) { viewModel in
                        ReceiveCurrencyView(viewModel: viewModel)
                    }
                    .innerContentPadding(12)
                    .interItemSpacing(10)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
