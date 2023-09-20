//
//  HighlightableViewModifier.swift
//  Tangem
//
//  Created by Andrey Fedorov on 19.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct HighlightableViewModifier: ViewModifier {
    let color: Color
    let duration: TimeInterval

    @State private var isHighlighted = false

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        isHighlighted = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            isHighlighted = false
                        }
                    }
            )
            .overlay(color.hidden(!isHighlighted))
    }
}

// MARK: - Convenience extensions

extension View {
    func highlightable(
        color: Color,
        duration: TimeInterval = 1.0 / 3.0
    ) -> some View {
        modifier(HighlightableViewModifier(color: color, duration: duration))
    }
}
