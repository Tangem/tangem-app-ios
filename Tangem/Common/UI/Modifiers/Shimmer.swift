//
//  Shimmer.swift
//  TangemApp
//
//  Created by Sergey Balashov on 09.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public struct Shimmer: ViewModifier {
    @State private var isAppeared: Bool = false
    @State private var gradientPoints: GradientPoints

    // It doesn't matter which color we use in gradient
    // Because we use `.mask` in `body` and it just add transparency to center of the view
    private let gradient = Gradient(colors: [.black, .black.opacity(0.4), .black])
    private let activeAnimation = Animation.linear(duration: 1).repeatForever(autoreverses: false)
    private let stopAnimation = Animation.linear(duration: 0)
    private let idlePoints: GradientPoints
    private let animationPoints: GradientPoints

    init(bandSize: CGFloat = 1) {
        let topLeading = UnitPoint.topLeading // 0, 0
        let bottomLeading = UnitPoint.bottomTrailing // 1, 1

        idlePoints = GradientPoints(start: UnitPoint(x: topLeading.x - bandSize, y: topLeading.y - bandSize), end: topLeading)
        animationPoints = GradientPoints(start: bottomLeading, end: UnitPoint(x: bottomLeading.x + bandSize, y: bottomLeading.y + bandSize))

        gradientPoints = idlePoints
    }

    public func body(content: Content) -> some View {
        content
            .mask {
                LinearGradient(gradient: gradient, startPoint: gradientPoints.start, endPoint: gradientPoints.end)
            }
            .animation(isAppeared ? activeAnimation : stopAnimation, value: gradientPoints)
            .onAppear {
                guard !isAppeared else {
                    return
                }

                isAppeared = true
                gradientPoints = animationPoints
            }
            .onDisappear {
                guard isAppeared else {
                    return
                }

                isAppeared = false
                gradientPoints = idlePoints
            }
    }
}

private extension Shimmer {
    struct GradientPoints: Equatable, Animatable {
        let start: UnitPoint
        let end: UnitPoint
    }
}
