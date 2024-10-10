//
//  MarketsNavigationBarBackgroundView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 04.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct MarketsNavigationBarBackgroundView<Overlay>: View where Overlay: View {
    let backdropViewColor: Color
    let overlayContentHidingProgress: CGFloat
    let isNavigationBarBackgroundBackdropViewHidden: Bool
    let isListContentObscured: Bool
    let overlay: () -> Overlay

    var body: some View {
        ZStack {
            // A backdrop view with a solid background color, placed underneath the translucent navigation bar background
            // and visible when this translucent navigation bar background becomes transparent on bottom sheet minimizing.
            // Prevents the content of the list from being visible through the transparent translucent navigation bar background
            // (it just looks ugly).
            backdropViewColor
                .hidden(isNavigationBarBackgroundBackdropViewHidden)
                .animation(.linear(duration: 0.1), value: isNavigationBarBackgroundBackdropViewHidden)

            // Translucent navigation bar background, visible when list content is obscured by the navigation bar/overlay
            Rectangle()
                .fill(.bar)
                .visible(isListContentObscured)
                .overlay(alignment: .bottom) {
                    overlay()
                }
                .overlay(alignment: .bottom) {
                    listOverlaySeparator
                }
                .opacity(overlayContentHidingProgress) // Hides translucent navigation bar background on bottom sheet minimizing
        }
    }

    @ViewBuilder
    private var listOverlaySeparator: some View {
        Separator(height: .minimal, color: Colors.Stroke.primary)
            .visible(isListContentObscured)
    }
}

// MARK: - Convenience extensions

extension MarketsNavigationBarBackgroundView where Overlay == EmptyView {
    init(
        backdropViewColor: Color,
        overlayContentHidingProgress: CGFloat,
        isNavigationBarBackgroundBackdropViewHidden: Bool,
        isListContentObscured: Bool
    ) {
        self.init(
            backdropViewColor: backdropViewColor,
            overlayContentHidingProgress: overlayContentHidingProgress,
            isNavigationBarBackgroundBackdropViewHidden: isNavigationBarBackgroundBackdropViewHidden,
            isListContentObscured: isListContentObscured
        ) {
            EmptyView()
        }
    }
}
