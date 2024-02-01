//
//  SendCurrencyView.swift
//  Tangem
//
//  Created by Sergey Balashov on 16.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendCurrencyView: View {
    @ObservedObject private var viewModel: SendCurrencyViewModel
    @Binding private var decimalValue: DecimalNumberTextField.DecimalValue?
    @State private var isShaking: Bool = false

    private var didTapChangeCurrency: (() -> Void)?
    private var maxAmountAction: (() -> Void)?

    init(viewModel: SendCurrencyViewModel, decimalValue: Binding<DecimalNumberTextField.DecimalValue?>) {
        self.viewModel = viewModel
        _decimalValue = decimalValue
    }

    var body: some View {
        ExpressCurrencyView(viewModel: viewModel.expressCurrencyViewModel) {
            SendDecimalNumberTextField(
                decimalValue: $decimalValue,
                maximumFractionDigits: viewModel.maximumFractionDigits
            )
            .maximumFractionDigits(viewModel.maximumFractionDigits)
            .maxAmountAction(maxAmountAction)
            .offset(x: isShaking ? 10 : 0)
            .simultaneousGesture(TapGesture().onEnded {
                viewModel.textFieldDidTapped()
            })
            .onChange(of: viewModel.expressCurrencyViewModel.titleState) { titleState in
                guard case .insufficientFunds = titleState else {
                    return
                }

                isShaking = true
                withAnimation(.spring(response: 0.2, dampingFraction: 0.2, blendDuration: 0.2)) {
                    isShaking = false
                }
            }
        }
        .didTapChangeCurrency { didTapChangeCurrency?() }
    }
}

// MARK: - Setupable

extension SendCurrencyView: Setupable {
    func maxAmountAction(_ action: (() -> Void)?) -> Self {
        map { $0.maxAmountAction = action }
    }

    func didTapChangeCurrency(_ block: @escaping () -> Void) -> Self {
        map { $0.didTapChangeCurrency = block }
    }
}

struct SendCurrencyView_Preview: PreviewProvider {
    @State private static var decimalValue: DecimalNumberTextField.DecimalValue? = nil

    static let viewModels = [
        SendCurrencyViewModel(
            expressCurrencyViewModel: .init(
                titleState: .text(Localization.swappingFromTitle),
                balanceState: .loading,
                fiatAmountState: .loading,
                tokenIconState: .icon(TokenIconInfoBuilder().build(from: .blockchain(.ethereum(testnet: false)), isCustom: false)),
                symbolState: .loaded(text: "ETH"),
                canChangeCurrency: false
            ),
            maximumFractionDigits: 8
        ),
        SendCurrencyViewModel(
            expressCurrencyViewModel: .init(
                titleState: .text(Localization.swappingFromTitle),
                balanceState: .formatted("0.0058"),
                fiatAmountState: .loading,
                tokenIconState: .icon(TokenIconInfoBuilder().build(from: .blockchain(.cardano(extended: false)), isCustom: false)),
                symbolState: .loaded(text: "ADA"),
                canChangeCurrency: false
            ),
            maximumFractionDigits: 8
        ),
        SendCurrencyViewModel(
            expressCurrencyViewModel: .init(
                titleState: .text(Localization.swappingFromTitle),
                balanceState: .formatted("0.0058"),
                fiatAmountState: .loading,
                tokenIconState: .icon(TokenIconInfoBuilder().build(from: .blockchain(.polygon(testnet: false)), isCustom: false)),
                symbolState: .loaded(text: "MATIC"),
                canChangeCurrency: true
            ),
            maximumFractionDigits: 8
        ),
        SendCurrencyViewModel(
            expressCurrencyViewModel: .init(
                titleState: .text(Localization.swappingFromTitle),
                balanceState: .formatted("0.0058"),
                fiatAmountState: .loaded(text: "1100.46"),
                tokenIconState: .icon(TokenIconInfoBuilder().build(from: .blockchain(.polygon(testnet: false)), isCustom: false)),
                symbolState: .loaded(text: "MATIC"),
                canChangeCurrency: true
            ),
            maximumFractionDigits: 8
        ),
        SendCurrencyViewModel(
            expressCurrencyViewModel: .init(
                titleState: .text(Localization.swappingFromTitle),
                balanceState: .formatted("0.0058"),
                fiatAmountState: .loaded(text: "2100.46 $"),
                tokenIconState: .icon(TokenIconInfoBuilder().build(from: .token(.tetherMock, .polygon(testnet: false)), isCustom: false)),
                symbolState: .loaded(text: "USDT"),
                canChangeCurrency: true
            ),
            maximumFractionDigits: 8
        ),
        SendCurrencyViewModel(
            expressCurrencyViewModel: .init(
                titleState: .text(Localization.swappingFromTitle),
                balanceState: .formatted("0.0058"),
                fiatAmountState: .loaded(text: "2100.46 $"),
                priceChangePercent: "-24.3 %",
                tokenIconState: .icon(TokenIconInfoBuilder().build(from: .token(.tetherMock, .polygon(testnet: false)), isCustom: false)),
                symbolState: .loaded(text: "USDT"),
                canChangeCurrency: true
            ),
            maximumFractionDigits: 8
        ),
    ]

    static var previews: some View {
        ZStack {
            Colors.Background.secondary

            VStack {
                ForEach(viewModels) { viewModel in
                    GroupedSection(viewModel) { viewModel in
                        SendCurrencyView(viewModel: viewModel, decimalValue: $decimalValue)
                    }
                    .interSectionPadding(12)
                    .interItemSpacing(10)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
