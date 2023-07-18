//
//  CardsInfoPagerContentAnimationModifier.swift
//  Tangem
//
//  Created by Andrey Fedorov on 18.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

/// This animator is responsible for applying visual effects (such as vertical offset and opacity changes)
/// for the `content` part of the pager view.
struct CardsInfoPagerContentAnimationModifier: AnimatableModifier {
    var progress: CGFloat
    let verticalOffset: CGFloat
    let hasNextIndexToSelect: Bool

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        let ratio = !hasNextIndexToSelect && progress > 0.5
            ? 1.0
            : abs(sin(.pi * progress))

        content
            .opacity(1.0 - Double(ratio))
            .offset(y: verticalOffset * ratio)
    }
}
