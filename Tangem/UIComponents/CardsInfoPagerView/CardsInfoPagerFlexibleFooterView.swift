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

    var isMediumSizeContent: Bool {
        contentSizeHeight >= minContentSizeHeight && contentSizeHeight < maxContentSizeHeight
    }

    var isLargeSizeContent: Bool {
        contentSizeHeight >= maxContentSizeHeight
    }

    var isSmallSizeContent: Bool {
        !isMediumSizeContent && !isLargeSizeContent
    }

    private var footerViewHeight: CGFloat {
        if contentSizeHeight >= minContentSizeHeight, contentSizeHeight < maxContentSizeHeight {
            return max(maxContentSizeHeight - contentSizeHeight, bottomContentInset)
        } else if contentSizeHeight >= maxContentSizeHeight {
            return bottomContentInset + Constants.marketsHitTooltipHeight
        }

        let spaceContentSizeHeight = ((viewportSize.height - contentSizeHeight) - headerHeight) + headerTopInset

        return spaceContentSizeHeight
    }

    var body: some View {
        ZStack {
            Color.clear
                .frame(height: footerViewHeight)
                .background(.yellow)

            if footerViewHeight > Constants.marketsHitTooltipComplexSpace {
                containerMarketsHintView
            }
        }
        .frame(height: footerViewHeight)
    }

    private var containerMarketsHintView: some View {
        VStack(alignment: .center, spacing: .zero) {
            topSpacerMarketsHintView

            hintView

            bottomSpacerMarketsHintView
        }
        .animation(.easeIn(duration: 0.3), value: UUID())
    }

    @ViewBuilder
    private var topSpacerMarketsHintView: some View {
        if isSmallSizeContent || isMediumSizeContent {
            Spacer(minLength: 12)
        } else if isLargeSizeContent {
            FixedSpacer(height: 12)
        }
    }

    @ViewBuilder
    private var bottomSpacerMarketsHintView: some View {
        if isSmallSizeContent {
            FixedSpacer(height: Constants.marketsHitTooltipBottomSpace)
        } else if isLargeSizeContent {
            Spacer(minLength: Constants.marketsHitTooltipBottomSpace)
        } else if isMediumSizeContent {
            
        }
    }

    private var hintView: some View {
        VStack(alignment: .center, spacing: .zero) {
            Text(Localization.marketsHint)
                .multilineTextAlignment(.center)
                .style(Fonts.Regular.footnote, color: Colors.Icon.informative)

            Assets.chevronDown12.image
        }
        .frame(width: 160)
    }
}

extension CardsInfoPagerFlexibleFooterView {
    enum Constants {
        static let marketsHitTooltipHeight: CGFloat = 56.0
        static let marketsHitTooltipComplexSpace: CGFloat = 92.0
        static let marketsHitTooltipBottomSpace: CGFloat = 24.0
    }
}
