//
//  MarketsTokenDetailsScrollState.swift
//  Tangem
//
//  Created by Dmitry Fedorov on 05.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

extension ScrollViewOffsetHandler where T == MarketsNavigationBarTitle.State {
    static func marketTokenDetails(initialState: MarketsNavigationBarTitle.State, labelOffset: CGFloat) -> Self {
        self.init(initialState: initialState) { contentOffset in
            let startAppearingOffset = labelOffset + MarketsTokenDetailsConstants.additionalOffset

            let titleOffset: CGFloat

            if contentOffset.y > startAppearingOffset {
                titleOffset = clamp(
                    (contentOffset.y - startAppearingOffset) / MarketsTokenDetailsConstants.moveSpeedRatio,
                    min: 0.0,
                    max: MarketsTokenDetailsConstants.maxTitleOffset
                )
            } else {
                titleOffset = 0
            }

            guard titleOffset > MarketsTokenDetailsConstants.minPriceDisplayOffset else {
                return MarketsNavigationBarTitle.State(
                    priceOpacity: nil,
                    titleOffset: titleOffset
                )
            }

            guard titleOffset <= MarketsTokenDetailsConstants.maxTitleOffset else {
                return MarketsNavigationBarTitle.State(
                    priceOpacity: nil,
                    titleOffset: MarketsTokenDetailsConstants.maxTitleOffset
                )
            }

            let priceOpacity = (titleOffset - MarketsTokenDetailsConstants.minPriceDisplayOffset) / (MarketsTokenDetailsConstants.maxTitleOffset - MarketsTokenDetailsConstants.minPriceDisplayOffset)

            return MarketsNavigationBarTitle.State(
                priceOpacity: priceOpacity,
                titleOffset: titleOffset
            )
        }
    }

    enum MarketsTokenDetailsConstants {
        static let maxTitleOffset: CGFloat = 16
        static let additionalOffset: CGFloat = 12
        static let moveSpeedRatio: CGFloat = 2 // resulting title label offset change speed is twice as slow as contentOffset
        static let minPriceDisplayOffset: CGFloat = 8
    }
}
