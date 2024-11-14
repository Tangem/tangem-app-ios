//
//  PendingExpressTxTokenInfoView.swift
//  TangemApp
//
//  Created by Aleksei Muraveinik on 14.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct PendingExpressTxTokenInfoView: View {
    private let tokenIconInfo: TokenIconInfo
    private let amountText: String
    private let fiatAmountTextState: LoadableTextView.State

    private let iconSize: CGSize

    init(
        tokenIconInfo: TokenIconInfo,
        amountText: String,
        fiatAmountTextState: LoadableTextView.State,
        iconSize: CGSize = CGSize(bothDimensions: 36)
    ) {
        self.tokenIconInfo = tokenIconInfo
        self.amountText = amountText
        self.fiatAmountTextState = fiatAmountTextState
        self.iconSize = iconSize
    }

    var body: some View {
        HStack(spacing: 12) {
            TokenIcon(tokenIconInfo: tokenIconInfo, size: iconSize)

            VStack(alignment: .leading, spacing: 2) {
                SensitiveText(amountText)
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
