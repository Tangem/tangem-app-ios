//
//  TokenItemViewTrailingComponent.swift
//  Tangem
//
//  Created by Andrey Fedorov on 06.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenItemViewTrailingComponent: View {
    let isWithError: Bool
    let errorMessage: String?
    let balanceFiat: LoadableTextView.State
    let changePercentage: LoadableTextView.State

    var body: some View {
        VStack(alignment: .trailing) {
            if isWithError, let errorMessage {
                Text(errorMessage)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            } else {
                LoadableTextView(
                    state: balanceFiat,
                    font: Fonts.Regular.subheadline,
                    textColor: Colors.Text.primary1,
                    loaderSize: .init(width: 40, height: 12),
                    loaderTopPadding: 4
                )

                LoadableTextView(
                    state: changePercentage,
                    font: Fonts.Regular.footnote,
                    textColor: Colors.Text.tertiary,
                    loaderSize: .init(width: 40, height: 12),
                    loaderTopPadding: 6
                )
            }
        }
    }
}
