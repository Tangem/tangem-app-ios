//
//  PendingExpressTxAmountView.swift
//  TangemApp
//
//  Created by Aleksei Muraveinik on 11.11.24..
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct PendingExpressTxAmountView: View {
    let timeString: String
    let sourceTokenIconInfo: TokenIconInfo
    let sourceAmountText: String
    let sourceFiatAmountTextState: LoadableTextView.State
    let destinationTokenIconInfo: TokenIconInfo
    let destinationAmountText: String
    let destinationFiatAmountTextState: LoadableTextView.State

    private let iconSize = CGSize(bothDimensions: 36)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 0) {
                Text(Localization.expressEstimatedAmount)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                Spacer(minLength: 8)

                Text(timeString)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }

            HStack(spacing: 12) {
                tokenInfo(
                    with: sourceTokenIconInfo,
                    cryptoAmountText: sourceAmountText,
                    fiatAmountTextState: sourceFiatAmountTextState
                )

                Assets.arrowRightMini.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(size: .init(bothDimensions: 12))
                    .foregroundColor(Colors.Icon.informative)

                tokenInfo(
                    with: destinationTokenIconInfo,
                    cryptoAmountText: destinationAmountText,
                    fiatAmountTextState: destinationFiatAmountTextState
                )
            }
        }
        .defaultRoundedBackground(with: Colors.Background.action)
    }

    private func tokenInfo(with tokenIconInfo: TokenIconInfo, cryptoAmountText: String, fiatAmountTextState: LoadableTextView.State) -> some View {
        HStack(spacing: 12) {
            TokenIcon(tokenIconInfo: tokenIconInfo, size: iconSize)

            VStack(alignment: .leading, spacing: 2) {
                SensitiveText(cryptoAmountText)

                    .style(Fonts.Regular.footnote, color: Colors.Text.primary1)

                LoadableTextView(
                    state: fiatAmountTextState,
                    font: Fonts.Regular.caption1,
                    textColor: Colors.Text.tertiary,
                    loaderSize: .init(width: 52, height: 12),
                    isSensitiveText: true
                )
            }
        }
    }
}
