//
//  CardsInfoPagerScrollViewHelpersFactory.swift
//  Tangem
//
//  Created by Andrey Fedorov on 05.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct CardsInfoPagerScrollViewHelpersFactory {
    let headerPlaceholderTopInset: CGFloat
    let headerAutoScrollThresholdRatio: CGFloat
    let headerPlaceholderHeight: CGFloat
    let contentOffset: Binding<CGPoint>

    func makeConnector(forPageAtIndex pageIndex: Int) -> CardsInfoPagerScrollViewConnector {
        let headerPlaceholderView = makeHeaderPlaceholderView(forPageAtIndex: pageIndex)
        return CardsInfoPagerScrollViewConnector(
            contentOffset: contentOffset,
            headerPlaceholderView: headerPlaceholderView,
            headerPlaceholderTopInset: headerPlaceholderTopInset,
            headerPlaceholderHeight: headerPlaceholderHeight
        )
    }

    private func makeHeaderPlaceholderView(forPageAtIndex pageIndex: Int) -> CardsInfoPageHeaderPlaceholderView {
        return CardsInfoPageHeaderPlaceholderView(
            expandedHeaderScrollTargetIdentifier: makeExpandedHeaderScrollTargetIdentifier(forPageAtIndex: pageIndex),
            collapsedHeaderScrollTargetIdentifier: makeCollapsedHeaderScrollTargetIdentifier(forPageAtIndex: pageIndex),
            headerPlaceholderTopInset: headerPlaceholderTopInset
        )
    }

    private func makeExpandedHeaderScrollTargetIdentifier(
        forPageAtIndex pageIndex: Int
    ) -> some Hashable {
        return "expandedHeaderScrollTargetIdentifier_\(pageIndex)"
    }

    private func makeCollapsedHeaderScrollTargetIdentifier(
        forPageAtIndex pageIndex: Int
    ) -> some Hashable {
        return "collapsedHeaderScrollTargetIdentifier_\(pageIndex)"
    }
}
