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
                PendingExpressTxTokenInfoView(
                    tokenIconInfo: sourceTokenIconInfo,
                    amountText: sourceAmountText,
                    fiatAmountTextState: sourceFiatAmountTextState
                )

                Assets.arrowRightMini.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(size: .init(bothDimensions: 12))
                    .foregroundColor(Colors.Icon.informative)

                PendingExpressTxTokenInfoView(
                    tokenIconInfo: destinationTokenIconInfo,
                    amountText: destinationAmountText,
                    fiatAmountTextState: destinationFiatAmountTextState
                )
            }
        }
        .defaultRoundedBackground(with: Colors.Background.action)
    }
}
