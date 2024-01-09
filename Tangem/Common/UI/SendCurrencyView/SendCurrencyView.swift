//
//  SendCurrencyView.swift
//  Tangem
//
//  Created by Sergey Balashov on 16.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendCurrencyView: View {
    private var viewModel: SendCurrencyViewModel
    @Binding private var decimalValue: DecimalNumberTextField.DecimalValue?

    private let tokenIconSize = CGSize(width: 36, height: 36)
    private var didTapChangeCurrency: (() -> Void)?
    private var didTapMaxAmountAction: (() -> Void)?

    init(viewModel: SendCurrencyViewModel, decimalValue: Binding<DecimalNumberTextField.DecimalValue?>) {
        self.viewModel = viewModel
        _decimalValue = decimalValue
    }

    var body: some View {
        VStack(spacing: 8) {
            headerLabels

            mainContent
        }
        .padding(.all, 14)
        .background(Colors.Background.action)
        .cornerRadius(14)
    }

    private var headerLabels: some View {
        HStack(spacing: 0) {
            switch viewModel.headerState {
            case .header:
                Text(Localization.swappingFromTitle)
                    .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
            case .insufficientFunds:
                Text(Localization.swappingInsufficientFunds)
                    .style(Fonts.Regular.caption1, color: Colors.Text.warning)
            }

            Spacer()

            switch viewModel.balance {
            case .idle:
                EmptyView()
            case .loading:
                SkeletonView()
                    .frame(width: 100, height: 13)
                    .cornerRadius(6)
            case .loaded:
                SensitiveText(builder: Localization.commonBalance, sensitive: viewModel.balanceString)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            case .formatted(let value):
                SensitiveText(builder: Localization.commonBalance, sensitive: value)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var currencyContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            SendDecimalNumberTextField(decimalValue: $decimalValue, maximumFractionDigits: viewModel.maximumFractionDigits, font: Fonts.Regular.title1)
                .maximumFractionDigits(viewModel.maximumFractionDigits)
                .didTapMaxAmount { didTapMaxAmountAction?() }
                .simultaneousGesture(TapGesture().onEnded {
                    viewModel.textFieldDidTapped()
                })

            switch viewModel.fiatValue {
            case .idle:
                EmptyView()
            case .loading:
                SkeletonView()
                    .frame(width: 50, height: 13)
                    .cornerRadius(6)
            case .loaded:
                Text(viewModel.fiatValueString)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            case .formatted(let value):
                Text(value)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }
        }
    }

    private var mainContent: some View {
        HStack(alignment: .top, spacing: 0) {
            currencyContent

            Spacer()

            SwappingTokenIconView(state: viewModel.tokenIconState)
                .onTap(viewModel.canChangeCurrency ? didTapChangeCurrency : nil)
        }
    }
}

// MARK: - Setupable

extension SendCurrencyView: Setupable {
    func didTapMaxAmount(_ action: @escaping () -> Void) -> Self {
        map { $0.didTapMaxAmountAction = action }
    }

    func didTapChangeCurrency(_ block: @escaping () -> Void) -> Self {
        map { $0.didTapChangeCurrency = block }
    }
}

struct SendCurrencyView_Preview: PreviewProvider {
    @State private static var decimalValue: DecimalNumberTextField.DecimalValue? = nil

    static let viewModels: [SendCurrencyViewModel] = [
        SendCurrencyViewModel(
            balance: .loading,
            fiatValue: .loading,
            maximumFractionDigits: 8,
            canChangeCurrency: true,
            tokenIconState: .loaded(
                imageURL: TokenIconURLBuilder().iconURL(id: "bitcoin", size: .large),
                symbol: "BTC"
            )
        ),
        SendCurrencyViewModel(
            balance: .loaded(3043.75),
            fiatValue: .loaded(1000.71),
            maximumFractionDigits: 8,
            canChangeCurrency: true,
            tokenIconState: .loaded(
                imageURL: TokenIconURLBuilder().iconURL(id: "bitcoin", size: .large),
                symbol: "BTC"
            )
        ),
    ]

    static var previews: some View {
        ZStack {
            Colors.Background.secondary

            VStack {
                ForEach(viewModels) {
                    SendCurrencyView(viewModel: $0, decimalValue: $decimalValue)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
