//
//  MainBottomSheetHintView.swift
//  Tangem
//
//  Created by skibinalexander on 17.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MainBottomSheetHintView: View {
    let isDraggingHorizontally: Bool
    let didScrollToBottom: Bool
    let scrollOffset: CGPoint
    let viewportSize: CGSize
    let contentSize: CGSize
    let scrollViewBottomContentInset: CGFloat

    var body: some View {
        let _ = Self._printChanges()

        VStack {
            hintView
                .opacity(updateOpacity())
        }
        .background(.clear)
//        .frame(width: Constants.staticWidth)
        .offset(y: -Constants.staticOffset)
        .transition(.asymmetric(insertion: .move(edge: .top), removal: .opacity))
        .animation(.easeInOut(duration: 0.15))
    }

    private var hintView: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(Localization.marketsHint)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .style(Fonts.Regular.footnote, color: Colors.Icon.informative)

            Assets.chevronDown12.image
        }
    }

    private func updateOpacity() -> CGFloat {
        let contentSizeHeight = contentSize.height
        let scrollOffsetHeight = scrollOffset.y
        let viewportSizeHeight = viewportSize.height
        let diffContentSizeWithScrollOffset = viewportSizeHeight - (contentSizeHeight - scrollOffsetHeight)

        guard scrollOffsetHeight > -Constants.headerVerticalPadding, didScrollToBottom, !isDraggingHorizontally else {
            return 0
        }

        if diffContentSizeWithScrollOffset - scrollViewBottomContentInset > Constants.staticOffset {
            return 1
        }

        return 0
    }
}

private extension MainBottomSheetHintView {
    private enum Constants {
        static var headerVerticalPadding: CGFloat { 4.0 }
        static var staticWidth: CGFloat { 160.0 }
        static var staticOffset: CGFloat { 92.0 }
    }
}
