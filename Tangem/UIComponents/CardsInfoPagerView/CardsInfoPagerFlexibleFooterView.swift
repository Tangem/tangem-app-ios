//
//  CardsInfoPagerFlexibleFooterView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 12.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct CardsInfoPagerFlexibleFooterView: View {
    let contentSize: CGSize
    let viewportSize: CGSize
    let headerTopInset: CGFloat
    let headerHeight: CGFloat

    private var footerViewHeight: CGFloat {
        let minContentSizeHeight = viewportSize.height + .ulpOfOne
        let maxContentSizeHeight = viewportSize.height + headerHeight + headerTopInset

        if (minContentSizeHeight ..< maxContentSizeHeight) ~= contentSize.height {
            return maxContentSizeHeight - contentSize.height
        }

        return 0.0
    }

    var body: some View {
        Color.clear
            .frame(height: footerViewHeight)
    }
}
