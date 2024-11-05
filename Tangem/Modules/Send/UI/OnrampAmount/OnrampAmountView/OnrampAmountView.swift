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
        VStack(spacing: 18) {
            IconView(
                url: viewModel.fiatIconURL,
                size: CGSize(width: 36, height: 36),
                // Kingfisher shows a gray background even if it has a cached image
                forceKingfisher: false
            )
            .matchedGeometryEffect(id: namespace.names.tokenIcon, in: namespace.id)

            VStack(spacing: 6) {
                SendDecimalNumberTextField(viewModel: viewModel.decimalNumberTextFieldViewModel)
                    .initialFocusBehavior(.noFocus)
                    .alignment(.center)
                    .prefixSuffixOptions(viewModel.currentFieldOptions)
                    .minTextScale(SendAmountStep.Constants.amountMinTextScale)
                    .matchedGeometryEffect(id: namespace.names.amountCryptoText, in: namespace.id)
                    .skeletonable(isShown: viewModel.isLoading)

                // Keep empty text so that the view maintains its place in the layout
                Text(viewModel.alternativeAmount ?? " ")
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .lineLimit(1)
                    .matchedGeometryEffect(id: namespace.names.amountFiatText, in: namespace.id)

                bottomInfoText
            }
        }
    }

    private var bottomInfoText: some View {
        Group {
            switch viewModel.bottomInfoText {
            case .none:
                // Hold empty space
                Text(" ")
                    .style(Fonts.Regular.caption1, color: Colors.Text.warning)
            case .info(let string):
                Text(string)
                    .style(Fonts.Regular.caption1, color: Colors.Text.attention)
            case .error(let string):
                Text(string)
                    .style(Fonts.Regular.caption1, color: Colors.Text.warning)
            }
        }
        .multilineTextAlignment(.center)
        .lineLimit(2)
    }
}
