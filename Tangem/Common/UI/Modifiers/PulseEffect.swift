//
//  PulseEffect.swift
//  TangemApp
//
//  Created by Sergey Balashov on 15.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct PulseEffect: ViewModifier {
    @State private var pulseIsInMaxState: Bool = true

    private let range: ClosedRange<Double>
    private let duration: TimeInterval

    init(range: ClosedRange<Double> = 0.5 ... 1, duration: TimeInterval = 1) {
        self.range = range
        self.duration = duration
    }

    func body(content: Content) -> some View {
        content
            .opacity(pulseIsInMaxState ? range.upperBound : range.lowerBound)
            .onAppear { pulseIsInMaxState = false }
            .animation(.smooth(duration: duration).repeatForever(), value: pulseIsInMaxState)
    }
}
