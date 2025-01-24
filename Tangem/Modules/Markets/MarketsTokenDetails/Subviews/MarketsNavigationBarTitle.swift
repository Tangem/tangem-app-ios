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
        let priceOpacity: CGFloat?
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
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(1)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .animation(animation, value: state.titleOffset)

            if let price {
                pricePlaceholder(price)
                    .overlay {
                        if let opacity = state.priceOpacity {
                            priceText(price)
                                .opacity(opacity)
                                .animation(.default, value: state.priceOpacity)
                        }
                    }
            }
        }
    }

    private func pricePlaceholder(_ text: String) -> some View {
        priceText(text)
            .opacity(0)
            .frame(height: state.titleOffset)
            .animation(animation, value: state.titleOffset)
    }

    private func priceText(_ text: String) -> some View {
        Text(text)
            .style(Fonts.Bold.caption1, color: Colors.Text.tertiary)
            .fixedSize(horizontal: false, vertical: true)
            .lineLimit(1)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.6)
    }

    private var animation: Animation {
        .easeIn(duration: 0.15) // reduced to minimize animation lag on fast scrolling
    }
}
