//
//  CardsInfoPagerSwipeDiscoveryAnimationModifier.swift
//  Tangem
//
//  Created by Andrey Fedorov on 10.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct CardsInfoPagerSwipeDiscoveryAnimationModifier: AnimatableModifier {
    var progress: CGFloat
    let count: Int
    let offset: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        // Shifted and scaled sine to produce values from 0.0 to 1.0 and back `count` times
        let times = 2.0 * CGFloat(count)
        let scale = 0.5
        let phaseAdjustment = .pi * scale
        let phaseShift = 1.0
        let value = (phaseShift + sin(.pi * times * progress - phaseAdjustment)) * scale * offset

        content.offset(x: value)
    }
}
