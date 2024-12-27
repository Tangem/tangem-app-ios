//
//  PulseEffect.swift
//  TangemApp
//
//  Created by Sergey Balashov on 27.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct PulseEffect: ViewModifier {
    @State private var isPulsing: Bool = true
    private let range: ClosedRange<Double>
    private let duration: TimeInterval

    init(range: ClosedRange<Double>, duration: TimeInterval) {
        self.range = range
        self.duration = duration
    }

    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? range.upperBound : range.lowerBound)
            .onAppear { isPulsing = false }
            .animation(.smooth(duration: duration).repeatForever(), value: isPulsing)
    }
}

public extension View {
    func pulseEffect(range: ClosedRange<Double> = 0.5 ... 1, duration: TimeInterval = 1) -> some View {
        modifier(PulseEffect(range: range, duration: duration))
    }
}
