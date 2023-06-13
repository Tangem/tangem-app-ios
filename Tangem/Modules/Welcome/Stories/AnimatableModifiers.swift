//
//  AnimatableModifiers.swift
//  Tangem
//
//  Created by Andrey Chukavin on 05.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

private func normalize(progress: Double, start: Double, end: Double) -> Double {
    let value = (progress - start) / (end - start)
    return max(0, min(value, 1))
}

struct AnimatableScaleModifier: AnimatableModifier {
    var progress: Double
    let start: Double
    let end: Double
    let curve: (Double) -> Double

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(curve(normalizeProgress(progress)))
    }

    private func normalizeProgress(_ progress: Double) -> Double {
        normalize(progress: progress, start: start, end: end)
    }
}

struct AnimatableVisibilityModifier: AnimatableModifier {
    var progress: Double
    let start: Double
    let end: Double

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content
            .opacity((start <= progress && progress < end) ? 1 : 0)
    }
}

struct AnimatableOffsetModifier: AnimatableModifier {
    var progress: Double
    let start: Double
    let end: Double
    let curveX: (Double) -> Double
    let curveY: (Double) -> Double

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content
            .offset(
                x: curveX(normalizeProgress(progress)),
                y: curveY(normalizeProgress(progress))
            )
    }

    private func normalizeProgress(_ progress: Double) -> Double {
        normalize(progress: progress, start: start, end: end)
    }
}

// MARK: - Extensions

extension View {
    func storyTextAppearanceModifier(
        progress: Double,
        type: StoriesConstants.TextType,
        textBlockAppearance: StoriesConstants.TextBlockAppearance
    ) -> some View {
        modifier(AnimatableOffsetModifier(
            progress: progress,
            start: textBlockAppearance.time + type.timeOffset,
            end: textBlockAppearance.time + type.timeOffset + StoriesConstants.textAppearanceDuration,
            curveX: { _ in
                0
            }, curveY: {
                40 * pow(2, -15 * $0)
            }
        ))
        .modifier(AnimatableVisibilityModifier(
            progress: progress,
            start: textBlockAppearance.time + type.timeOffset,
            end: .infinity
        ))
    }

    func storyImageAppearanceModifier(
        progress: Double,
        start: Double,
        fastMovementStartCoefficient: Double,
        fastMovementSpeedCoefficient: Double,
        fastMovementEnd: Double,
        slowMovementSpeedCoefficient: Double
    ) -> some View {
        modifier(AnimatableScaleModifier(
            progress: progress,
            start: start,
            end: 1
        ) { progress in
            let fastMovementCurve: (Double) -> Double = {
                fastMovementStartCoefficient + pow(2, fastMovementSpeedCoefficient * $0)
            }

            if progress <= fastMovementEnd {
                return fastMovementCurve(progress)
            } else {
                return
                    fastMovementCurve(fastMovementEnd) -
                    slowMovementSpeedCoefficient * (progress - fastMovementEnd) / (1 - fastMovementEnd)
            }
        }
        )
    }
}
