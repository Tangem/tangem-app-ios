//
//  OnrampAmountView.swift
//  TangemApp
//
//  Created by Sergey Balashov on 15.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnrampAmountView: View {
    @ObservedObject var viewModel: OnrampAmountViewModel
    let namespace: SendAmountView.Namespace

    var body: some View {
        amountContent
            .defaultRoundedBackground(
                with: Colors.Background.action,
                geometryEffect: .init(
                    id: namespace.names.amountContainer,
                    namespace: namespace.id
                )
            )
    }

    private var amountContent: some View {
        VStack(spacing: 16) {
            tokenIconView

            textView
        }
        .padding(.vertical, 20)
    }

    @ViewBuilder
    private var tokenIconView: some View {
        let chevronSize: CGFloat = 9

        Button(action: viewModel.onChangeCurrencyTap) {
            HStack(spacing: 8) {
                // Use the `Spacer` for center `IconView`
                FixedSpacer(width: chevronSize)

                IconView(
                    url: viewModel.fiatIconURL,
                    size: CGSize(width: 36, height: 36),
                    // Kingfisher shows a gray background even if it has a cached image
                    forceKingfisher: false
                )

                Assets.chevronDownMini.image
                    .resizable()
                    .frame(size: .init(bothDimensions: chevronSize))
                    .foregroundColor(Colors.Icon.informative)
                    .hidden(viewModel.isLoading)
            }
        }
        .disabled(viewModel.isLoading)
        .matchedGeometryEffect(id: namespace.names.tokenIcon, in: namespace.id)
    }

    private var textView: some View {
        VStack(spacing: 6) {
            SendDecimalNumberTextField(viewModel: viewModel.decimalNumberTextFieldViewModel)
                .initialFocusBehavior(.noFocus)
                .alignment(.center)
                .prefixSuffixOptions(viewModel.currentFieldOptions)
                .minTextScale(SendAmountStep.Constants.amountMinTextScale)
                .matchedGeometryEffect(id: namespace.names.amountCryptoText, in: namespace.id)
                .skeletonable(isShown: viewModel.isLoading, width: 100, height: 28)

            LoadableTextView(
                state: viewModel.bottomInfoText.state,
                font: Fonts.Regular.footnote,
                textColor: viewModel.bottomInfoText.isError ? Colors.Text.warning : Colors.Text.tertiary,
                loaderSize: CGSize(width: 80, height: 13)
            )
            .lineLimit(2)
            .matchedGeometryEffect(id: namespace.names.amountFiatText, in: namespace.id)
        }
    }
}
