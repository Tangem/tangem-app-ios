//
//  MarketsTokenDetailsListedOnExchangesView.swift
//  Tangem
//
//  Created by Andrew Son on 26.09.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsTokenDetailsListedOnExchangesView: View {
    let exchangesCount: Int
    let buttonAction: () -> Void

    private var isListedOnExchanges: Bool {
        exchangesCount > 0
    }

    var body: some View {
        Group {
            if isListedOnExchanges {
                Button(action: buttonAction, label: {
                    content
                })
            } else {
                content
            }
        }
        .defaultRoundedBackground(with: Colors.Background.action)
    }

    private var content: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(Localization.marketsTokenDetailsListedOn)
                    .style(Fonts.Bold.footnote.weight(.semibold), color: Colors.Text.tertiary)

                Group {
                    if isListedOnExchanges {
                        Text(Localization.marketsTokenDetailsAmountExchanges(exchangesCount))
                    } else {
                        Text(Localization.marketsTokenDetailsEmptyExchanges)
                    }
                }
                .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
            }

            Spacer()

            if isListedOnExchanges {
                Assets.chevronRightWithOffset24.image
                    .renderingMode(.template)
                    .foregroundStyle(Colors.Icon.informative)
            }
        }
    }
}

#Preview {
    VStack {
        MarketsTokenDetailsListedOnExchangesView(exchangesCount: 10, buttonAction: {})

        MarketsTokenDetailsListedOnExchangesView(exchangesCount: 0, buttonAction: {})
    }
}
