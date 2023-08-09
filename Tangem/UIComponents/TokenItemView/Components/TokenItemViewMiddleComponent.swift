//
//  TokenItemViewMiddleComponent.swift
//  Tangem
//
//  Created by Andrey Fedorov on 06.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenItemViewMiddleComponent: View {
    let name: String
    let balance: LoadableTextView.State
    let hasPendingTransactions: Bool
    let isWithError: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(name)
                    .style(
                        Fonts.Bold.subheadline,
                        color: isWithError ? Colors.Text.tertiary : Colors.Text.primary1
                    )
                    .lineLimit(2)

                if hasPendingTransactions {
                    Assets.pendingTxIndicator.image
                }
            }

            if !isWithError {
                LoadableTextView(
                    state: balance,
                    font: Fonts.Regular.footnote,
                    textColor: Colors.Text.tertiary,
                    loaderSize: .init(width: 52, height: 12),
                    loaderTopPadding: 4
                )
            }
        }
    }
}
