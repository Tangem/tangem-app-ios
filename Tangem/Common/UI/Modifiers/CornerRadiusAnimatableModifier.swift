//
//  CornerRadiusAnimatableModifier.swift
//  Tangem
//
//  Created by Andrey Fedorov on 02.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct CornerRadiusAnimatableModifier<ModifiedClipShape>: AnimatableModifier where ModifiedClipShape: Shape {
    typealias ClipShapeModifications = (_ clipShape: RoundedRectangle) -> ModifiedClipShape

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    private var progress: Double
    private let cornerRadius: CGFloat
    private let cornerRadiusStyle: RoundedCornerStyle
    private let clipShapeModifications: ClipShapeModifications

    init(
        progress: Double,
        cornerRadius: CGFloat,
        cornerRadiusStyle: RoundedCornerStyle,
        clipShapeModifications: @escaping ClipShapeModifications = { $0 }
    ) {
        self.progress = progress
        self.cornerRadius = cornerRadius
        self.cornerRadiusStyle = cornerRadiusStyle
        self.clipShapeModifications = clipShapeModifications
    }

    func body(content: Content) -> some View {
        return content
            .clipShape(
                // Ok, a tricky part here: clip shape is a drawing-only (layout-neutral) modifier,
                // but it can be applied to the `content` view, which already has been modified by
                // the other drawing-only (layout-neutral) modifiers like `Offset`, `Scale`, etc.
                //
                // Therefore, we should replicate these modifications for the clip shape in order to
                // match the final appearance of `content` view and clip shape.
                //
                // Modifications provided by the caller, in the `clipShapeModifications` closure.
                clipShapeModifications(
                    RoundedRectangle(cornerRadius: cornerRadius, style: cornerRadiusStyle)
                )
            )
    }
}
