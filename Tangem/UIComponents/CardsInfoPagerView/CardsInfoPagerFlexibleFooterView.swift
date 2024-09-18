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
    let bottomContentInset: CGFloat

    var minContentSizeHeight: CGFloat {
        viewportSize.height - bottomContentInset + .ulpOfOne
    }

    var maxContentSizeHeight: CGFloat {
        viewportSize.height + headerHeight + headerTopInset
    }

    var contentSizeHeight: CGFloat {
        contentSize.height
    }

    private var footerViewHeight: CGFloat {
        if contentSizeHeight >= minContentSizeHeight, contentSizeHeight < maxContentSizeHeight {
            return max(maxContentSizeHeight - contentSizeHeight, bottomContentInset)
        } else if contentSizeHeight >= maxContentSizeHeight {
            return bottomContentInset
        }

        return 0
    }

    var body: some View {
        Color.clear
            .frame(height: footerViewHeight)
            .background(.yellow)
    }
}

// extension CardsInfoPagerFlexibleFooterView {
//    enum Constants {
//        static let marketsHitTooltipHeight: CGFloat = 56.0
//        static let marketsHitTooltipComplexSpace: CGFloat = 92.0
//        static let marketsHitTooltipBottomSpace: CGFloat = 24.0
//    }
// }
