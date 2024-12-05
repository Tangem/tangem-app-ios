//
//  MarketsScrollViewOffsetTracking.swift
//  Tangem
//
//  Created by Dmitry Fedorov on 05.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

extension ScrollViewOffsetMapper where T == MarketsNavigationBarTitle.State {
    static func marketTokenDetails(initialState: MarketsNavigationBarTitle.State) -> Self {
        self.init(initialState: initialState) { contentOffset in
            let startAppearingOffset: CGFloat = 42
            let fullAppearanceOffset: CGFloat = 16

            let minPriceDisplaySpacing = 8.0

            let titleSpacing: CGFloat

            if contentOffset.y > startAppearingOffset {
                titleSpacing = clamp(
                    (contentOffset.y - startAppearingOffset) / 2.0,
                    min: 0.0,
                    max: fullAppearanceOffset
                )
            } else {
                titleSpacing = 0
            }

            let showPrice = titleSpacing > minPriceDisplaySpacing

            let priceOpacity: CGFloat
            if titleSpacing > minPriceDisplaySpacing {
                priceOpacity = (titleSpacing - minPriceDisplaySpacing) / 8.0
            } else {
                priceOpacity = 0
            }

            return MarketsNavigationBarTitle.State(
                priceOpacity: priceOpacity,
                titleSpacing: titleSpacing,
                showPrice: showPrice
            )
        }
    }
}
