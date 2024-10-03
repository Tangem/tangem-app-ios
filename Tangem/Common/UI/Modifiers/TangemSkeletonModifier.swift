//
//  TangemSkeletonModifier.swift
//  Tangem
//
//  Created by Pavel Grechikhin on 30.05.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

extension View {
    @ViewBuilder
    func skeletonable(isShown: Bool, size: CGSize, radius: CGFloat = 3, paddings: EdgeInsets = EdgeInsets()) -> some View {
        modifier(
            SkeletonModifier(isShown: isShown, modificationType: .size(size: size, paddings: paddings), radius: radius)
        )
    }

    @ViewBuilder
    func skeletonable(isShown: Bool, radius: CGFloat = 3) -> some View {
        modifier(
            SkeletonModifier(isShown: isShown, modificationType: .overlay, radius: radius)
        )
    }
}

// MARK: Modifier for View

public struct SkeletonModifier: ViewModifier {
    private let isShown: Bool
    private let modificationType: ModificationType
    private let radius: CGFloat

    public init(isShown: Bool, modificationType: ModificationType, radius: CGFloat) {
        self.isShown = isShown
        self.modificationType = modificationType
        self.radius = radius
    }

    public func body(content: Content) -> some View {
        // We have to maintain the structural identity of the modified `content` view to avoid glitches
        // when 'skeleton view' is being hidden/shown during ongoing animation.
        //
        // DO NOT use any conditional statements (`if`, `switch`, etc) to show/hide 'skeleton view' here;
        // this will result in `_ConditionalContent` being used as an underlying view type,
        // effectively changing the structural identity of the modified `content` view.
        //
        // See https://www.objc.io/blog/2021/08/24/conditional-view-modifiers/ for details
        switch modificationType {
        case .overlay:
            content
                .overlay(
                    SkeletonView()
                        .cornerRadius(radius)
                        .hidden(!isShown)
                )
        case .size(let size, let paddings):
            // 'skeleton view' should control the layout of `ZStack` only if it's being shown;
            // otherwise, the layout should be controlled by the `content` view.
            //
            // We use different layout priorities here to achieve this behavior.
            let contentLayoutPriority = isShown ? 0.0 : 1.0
            let skeletonViewLayoutPriority = isShown ? 1.0 : 0.0

            ZStack {
                content
                    .hidden(isShown)
                    .layoutPriority(contentLayoutPriority)

                SkeletonView()
                    .frame(size: size)
                    .cornerRadius(radius)
                    .padding(paddings)
                    .hidden(!isShown)
                    .layoutPriority(skeletonViewLayoutPriority)
            }
        }
    }
}

public extension SkeletonModifier {
    enum ModificationType {
        case size(size: CGSize, paddings: EdgeInsets)
        case overlay
    }
}
