//
//  MarketsNavigationBarTitle.swift
//  TangemApp
//
//  Created by Dmitry Fedorov on 05.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsNavigationBarTitle: View {
    struct State: Equatable {
        let priceOpacity: CGFloat
        let titleSpacing: CGFloat
        let showPrice: Bool
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
                .animation(.easeInOut, value: state.titleSpacing)

            ZStack {
                Spacer()
                    .frame(height: state.titleSpacing)
                    .animation(.easeInOut, value: state.titleSpacing)
                if let price, state.showPrice {
                    Text(price)
                        .style(Fonts.Bold.caption1, color: Colors.Text.tertiary)
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                        .opacity(state.priceOpacity)
                        .animation(.default, value: state.priceOpacity)
                }
            }
        }
    }
}
