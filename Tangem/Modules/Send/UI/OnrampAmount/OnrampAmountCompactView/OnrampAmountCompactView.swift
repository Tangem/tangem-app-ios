//
//  OnrampAmountCompactView.swift
//  Tangem
//
//  Created by Sergey Balashov on 13.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct OnrampAmountCompactView: View {
    @ObservedObject var viewModel: OnrampAmountCompactViewModel
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
            IconView(
                url: viewModel.fiatIconURL,
                size: CGSize(width: 36, height: 36),
                // Kingfisher shows a gray background even if it has a cached image
                forceKingfisher: false
            )
            .matchedGeometryEffect(id: namespace.names.tokenIcon, in: namespace.id)

            VStack(spacing: 12) {
                textView

                providerView
            }
        }
        .padding(.top, 4)
    }

    private var textView: some View {
        VStack(spacing: 6) {
            SendDecimalNumberTextField(viewModel: viewModel.decimalNumberTextFieldViewModel)
                .initialFocusBehavior(.noFocus)
                .alignment(.center)
                .prefixSuffixOptions(viewModel.currentFieldOptions)
                .minTextScale(SendAmountStep.Constants.amountMinTextScale)
                .matchedGeometryEffect(id: namespace.names.amountCryptoText, in: namespace.id)
                .disabled(true) // TextField is read only

            // Keep empty text so that the view maintains its place in the layout
            Text(viewModel.alternativeAmount ?? " ")
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .lineLimit(1)
                .matchedGeometryEffect(id: namespace.names.amountFiatText, in: namespace.id)
        }
    }

    private var providerView: some View {
        HStack(spacing: 6) {
            Text("with")
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

            IconView(
                url: viewModel.providerIconURL,
                size: CGSize(width: 16, height: 16),
                // Kingfisher shows a gray background even if it has a cached image
                forceKingfisher: false
            )

            Text(viewModel.providerName ?? "")
                .style(Fonts.Regular.footnote, color: Colors.Text.primary1)
        }
    }
}
