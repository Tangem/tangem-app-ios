//
//  SkeletonView.swift
//  Tangem
//
//  Created by Sergey Balashov on 31.05.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

public struct SkeletonView: View {
    @State var isAppeared = false

    // Animatable data - https://developer.apple.com/documentation/swiftui/animatable
    @State var gradientPoints = Constants.idlePoints
    @State var oldShouldAnimateSkeleton: Bool?

    private let backgroundOpacity: Double = 1
    private let colors: [Color] = [
        Colors.Old.tangemSkeletonGray,
        Colors.Old.tangemSkeletonGray2,
        Colors.Old.tangemSkeletonGray3,
        Colors.Old.tangemSkeletonGray2,
        Colors.Old.tangemSkeletonGray,
    ]

    private let activeAnimation = Animation.linear(duration: 1).repeatForever(autoreverses: false)
    private let stopAnimation = Animation.linear(duration: 0)

    public init() {}

    public var body: some View {
        ZStack {
            backgroundView

            gradientView
        }
    }

    var backgroundView: some View {
        Rectangle()
            .foregroundColor(Colors.Old.tangemSkeletonGray)
            .opacity(backgroundOpacity)
    }

    var gradientView: some View {
        LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: gradientPoints.start,
            endPoint: gradientPoints.end
        )
        .animation(isAppeared ? activeAnimation : stopAnimation, value: gradientPoints)
        .opacity(0.8)
        .onAppear {
            guard !isAppeared else {
                return
            }

            isAppeared = true
            gradientPoints = Constants.animationPoints
        }
        .onDisappear {
            guard isAppeared else {
                return
            }

            isAppeared = false
            gradientPoints = Constants.idlePoints
        }
    }
}

private extension SkeletonView {
    private enum Constants {
        static let idlePoints = LinearGradientPoints(
            start: UnitPoint.point(position: -1, radius: 0),
            end: UnitPoint.point(position: 0, radius: 0)
        )

        static let animationPoints = LinearGradientPoints(
            start: UnitPoint.point(position: 1, radius: 0),
            end: UnitPoint.point(position: 2, radius: 2)
        )
    }
}

// MARK: Helper extensions

struct LinearGradientPoints: Equatable, Animatable {
    let start: UnitPoint
    let end: UnitPoint
}

private extension UnitPoint {
    static func point(position: CGFloat, radius: CGFloat) -> UnitPoint {
        return UnitPoint(x: position + radius, y: position + radius)
    }
}
