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
    @State private var isShaking: Bool = false

    private var didTapChangeCurrency: (() -> Void)?
    private var maxAmountAction: (() -> Void)?

    init(viewModel: SendCurrencyViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ExpressCurrencyView(viewModel: viewModel.expressCurrencyViewModel) {
            SendDecimalNumberTextField(viewModel: viewModel.decimalNumberTextFieldViewModel)
                .toolbarType(maxAmountAction.map { .maxAmount(action: $0) })
                .initialFocusBehavior(.immediateFocus)
                .minTextScale(SendAmountStep.Constants.amountMinTextScale)
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

// MARK: - Previews

struct SendCurrencyView_Preview: PreviewProvider {
    static let viewModels = [
        SendCurrencyViewModel(
            expressCurrencyViewModel: .init(
                titleState: .text(Localization.swappingFromTitle),
                balanceState: .loading,
                fiatAmountState: .loading,
                tokenIconState: .icon(TokenIconInfoBuilder().build(from: .blockchain(.init(.ethereum(testnet: false), derivationPath: nil)), isCustom: false)),
                symbolState: .loaded(text: "ETH"),
                canChangeCurrency: false
            ),
            decimalNumberTextFieldViewModel: .init(maximumFractionDigits: 8)
        ),
        SendCurrencyViewModel(
            expressCurrencyViewModel: .init(
                titleState: .text(Localization.swappingFromTitle),
                balanceState: .formatted("0.0058"),
                fiatAmountState: .loading,
                tokenIconState: .icon(TokenIconInfoBuilder().build(from: .blockchain(.init(.ethereum(testnet: false), derivationPath: nil)), isCustom: false)),
                symbolState: .loaded(text: "ADA"),
                canChangeCurrency: false
            ),
            decimalNumberTextFieldViewModel: .init(maximumFractionDigits: 8)
        ),
        SendCurrencyViewModel(
            expressCurrencyViewModel: .init(
                titleState: .text(Localization.swappingFromTitle),
                balanceState: .formatted("0.0058"),
                fiatAmountState: .loading,
                tokenIconState: .icon(TokenIconInfoBuilder().build(from: .blockchain(.init(.ethereum(testnet: false), derivationPath: nil)), isCustom: false)),
                symbolState: .loaded(text: "MATIC"),
                canChangeCurrency: true
            ),
            decimalNumberTextFieldViewModel: .init(maximumFractionDigits: 8)
        ),
        SendCurrencyViewModel(
            expressCurrencyViewModel: .init(
                titleState: .text(Localization.swappingFromTitle),
                balanceState: .formatted("0.0058"),
                fiatAmountState: .loaded(text: "1100.46"),
                tokenIconState: .icon(TokenIconInfoBuilder().build(from: .blockchain(.init(.ethereum(testnet: false), derivationPath: nil)), isCustom: false)),
                symbolState: .loaded(text: "MATIC"),
                canChangeCurrency: true
            ),
            decimalNumberTextFieldViewModel: .init(maximumFractionDigits: 8)
        ),
        SendCurrencyViewModel(
            expressCurrencyViewModel: .init(
                titleState: .text(Localization.swappingFromTitle),
                balanceState: .formatted("0.0058"),
                fiatAmountState: .loaded(text: "2100.46 $"),
                tokenIconState: .icon(TokenIconInfoBuilder().build(from: .token(.tetherMock, .init(.polygon(testnet: false), derivationPath: nil)), isCustom: false)),
                symbolState: .loaded(text: "USDT"),
                canChangeCurrency: true
            ),
            decimalNumberTextFieldViewModel: .init(maximumFractionDigits: 8)
        ),
        SendCurrencyViewModel(
            expressCurrencyViewModel: .init(
                titleState: .text(Localization.swappingFromTitle),
                balanceState: .formatted("0.0058"),
                fiatAmountState: .loaded(text: "2100.46 $"),
                priceChangeState: .percent("-24.3 %"),
                tokenIconState: .icon(TokenIconInfoBuilder().build(from: .token(.tetherMock, .init(.polygon(testnet: false), derivationPath: nil)), isCustom: false)),
                symbolState: .loaded(text: "USDT"),
                canChangeCurrency: true
            ),
            decimalNumberTextFieldViewModel: .init(maximumFractionDigits: 8)
        ),
    ]

    static var previews: some View {
        ZStack {
            Colors.Background.secondary

            VStack {
                ForEach(viewModels) { viewModel in
                    GroupedSection(viewModel) { viewModel in
                        SendCurrencyView(viewModel: viewModel)
                    }
                    .innerContentPadding(12)
                    .interItemSpacing(10)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
