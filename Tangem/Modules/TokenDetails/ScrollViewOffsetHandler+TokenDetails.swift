//
//  ScrollViewOffsetHandler+TokenDetails.swift
//  Tangem
//
//  Created by Andrey Fedorov on 30.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

extension ScrollViewOffsetHandler where T == Double {
    static func tokenDetails(tokenIconSizeSettings: IconViewSizeSettings, headerTopPadding: CGFloat) -> Self {
        self.init(initialState: .zero) { contentOffset in
            let iconHeight = tokenIconSizeSettings.iconSize.height
            let startAppearingOffset = headerTopPadding + iconHeight

            let fullAppearanceDistance = iconHeight / 2.0
            let fullAppearanceOffset = startAppearingOffset + fullAppearanceDistance

            return clamp(
                (contentOffset.y - startAppearingOffset) / (fullAppearanceOffset - startAppearingOffset),
                min: 0.0,
                max: 1.0
            )
        }
    }
}
