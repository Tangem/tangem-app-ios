//
//  MainBottomSheetHintView.swift
//  Tangem
//
//  Created by skibinalexander on 17.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSwiftUIUtils

struct MainBottomSheetHintView: View {
    let isDraggingHorizontally: Bool
    let didScrollToBottom: Bool
    let scrollOffset: CGPoint
    let viewportSize: CGSize
    let contentSize: CGSize
    let scrollViewBottomContentInset: CGFloat

    @State private var hintSizeHeight: CGFloat = .zero

    var body: some View {
        VStack {
            FixedSpacer(height: 12)

            hintView
                .opacity(updateOpacity().rawValue)
        }
        .background(.clear)
        .frame(width: Constants.staticWidth)
        .offset(y: -(hintSizeHeight + Constants.staticOffset))
        .transition(.asymmetric(insertion: .move(edge: .top), removal: .opacity))
        .animation(.easeInOut(duration: 0.2), value: UUID())
    }

    private var hintView: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(Localization.marketsHint)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .style(Fonts.Regular.footnote, color: Colors.Icon.informative)

            Assets.chevronDown12.image
        }
        .readGeometry(\.frame.size.height, bindTo: $hintSizeHeight)
    }

    private func updateOpacity() -> StateOpacity {
        let contentSizeHeight = contentSize.height
        let scrollOffsetHeight = scrollOffset.y
        let viewportSizeHeight = viewportSize.height
        let сontentSizeWithScrollOffset = viewportSizeHeight - (contentSizeHeight - scrollOffsetHeight)

        /*
         - The first part of the condition is needed to determine the pullToRefresh
         - The second part of the condition determines that the scroll borders are scrolled to the end
         - The third condition forcibly hides the animation if we use a horizontal pager
         */
        guard
            scrollOffsetHeight > -Constants.headerVerticalPadding,
            didScrollToBottom,
            !isDraggingHorizontally,
            viewportSizeHeight > 0
        else {
            return .hide
        }

        if viewportSizeHeight - contentSizeHeight > scrollViewBottomContentInset + (hintSizeHeight + Constants.staticOffset) {
            /// This condition is met when the list of tokens is significantly smaller than the visible area and we must always show a hint
            return .show
        } else if сontentSizeWithScrollOffset - scrollViewBottomContentInset > (hintSizeHeight + Constants.staticOffset) {
            /// This condition determines that the size of the content borders on the visible area or is larger than the visible area, therefore, the use of overscroll logic is required.
            return .show
        }

        return .hide
    }
}

private extension MainBottomSheetHintView {
    enum Constants {
        static let headerVerticalPadding: CGFloat = 4.0
        static let staticOffset: CGFloat = 32.0
        static let staticWidth: CGFloat = 162.0
    }

    enum StateOpacity: CGFloat {
        case show = 1.0
        case hide = 0.0
    }
}
