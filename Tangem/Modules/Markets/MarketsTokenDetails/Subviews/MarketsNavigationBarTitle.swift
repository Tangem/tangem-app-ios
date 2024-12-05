//
//  MarketsNavigationBarTitle.swift
//  TangemApp
//
//  Created by Dmitry Fedorov on 05.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsNavigationBarTitle: View {
    enum PriceVisibility: Equatable {
        case hidden
        case visible(opacity: CGFloat)
    }

    struct State: Equatable {
        let priceVisibility: PriceVisibility
        let titleOffset: CGFloat
    }

    let tokenName: String
    let price: String?

    let state: State

    init(tokenName: String, price: String?, state: State) {
        self.tokenName = tokenName
        self.price = price
        self.state = state
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(tokenName)
                .style(Fonts.Bold.body, color: Colors.Text.primary1)
                .lineLimit(1)
                .multilineTextAlignment(.center)
                .animation(.easeInOut, value: state.titleOffset)

            ZStack {
                Spacer()
                    .frame(height: state.titleOffset)
                    .animation(.easeInOut, value: state.titleOffset)
                if let price, case .visible(let opacity) = state.priceVisibility {
                    Text(price)
                        .style(Fonts.Bold.caption1, color: Colors.Text.tertiary)
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                        .opacity(opacity)
                        .animation(.default, value: state.priceVisibility)
                }
            }
        }
    }
}
