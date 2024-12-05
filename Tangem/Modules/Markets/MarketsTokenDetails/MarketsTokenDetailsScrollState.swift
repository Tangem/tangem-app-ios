//
//  MarketsTokenDetailsScrollState.swift
//  Tangem
//
//  Created by Dmitry Fedorov on 05.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

extension ScrollViewOffsetMapper where T == MarketsNavigationBarTitle.State {
    static func marketTokenDetails(initialState: MarketsNavigationBarTitle.State, labelOffset: CGFloat) -> Self {
        self.init(initialState: initialState) { contentOffset in
            let startAppearingOffset = labelOffset + Constants.additionalOffset

            let titleOffset: CGFloat

            if contentOffset.y > startAppearingOffset {
                titleOffset = clamp(
                    (contentOffset.y - startAppearingOffset) / Constants.moveSpeedRatio,
                    min: 0.0,
                    max: Constants.maxTitleOffset
                )
            } else {
                titleOffset = 0
            }

            guard titleOffset > Constants.minPriceDisplayOffset else {
                return MarketsNavigationBarTitle.State(
                    priceVisibility: .hidden,
                    titleOffset: titleOffset
                )
            }

            guard titleOffset <= Constants.maxTitleOffset else {
                return MarketsNavigationBarTitle.State(
                    priceVisibility: .hidden,
                    titleOffset: Constants.maxTitleOffset
                )
            }

            let priceOpacity = (titleOffset - Constants.minPriceDisplayOffset) / (Constants.maxTitleOffset - Constants.minPriceDisplayOffset)

            return MarketsNavigationBarTitle.State(
                priceVisibility: .visible(opacity: priceOpacity),
                titleOffset: titleOffset
            )
        }
    }

    enum Constants {
        static let maxTitleOffset: CGFloat = 16
        static let additionalOffset: CGFloat = 12
        static let moveSpeedRatio: CGFloat = 2 // resulting title label offset change speed is twice as slow as contentOffset
        static let minPriceDisplayOffset: CGFloat = 8
    }
}
