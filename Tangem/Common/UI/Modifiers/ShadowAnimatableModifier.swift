//
//  ShadowAnimatableModifier.swift
//  Tangem
//
//  Created by Andrey Fedorov on 02.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct ShadowAnimatableModifier: AnimatableModifier {
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    private var progress: Double
    private let color: Color
    private let radius: CGFloat
    private let offset: CGPoint

    init(
        progress: Double,
        color: Color,
        radius: CGFloat,
        offset: CGPoint = .zero
    ) {
        self.progress = progress
        self.color = color
        self.radius = radius
        self.offset = offset
    }

    func body(content: Content) -> some View {
        return content
            .shadow(
                color: color.opacity(progress),
                radius: radius,
                x: offset.x,
                y: offset.y
            )
    }
}
