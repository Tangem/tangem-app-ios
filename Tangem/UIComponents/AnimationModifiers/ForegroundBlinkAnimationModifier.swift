//
//  ForegroundBlinkAnimationModifier.swift
//  Tangem
//
//  Created by Andrew Son on 24/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct ForegroundBlinkAnimationModifier: ViewModifier {
    let publisher: Published<Change>.Publisher
    let positiveColor: Color
    let negativeColor: Color
    let originalColor: Color
    let duration: Double

    @State private var targetColor: Color

    init(publisher: Published<Change>.Publisher, positiveColor: Color, negativeColor: Color, originalColor: Color, duration: Double) {
        self.publisher = publisher
        self.positiveColor = positiveColor
        self.negativeColor = negativeColor
        self.originalColor = originalColor
        self.duration = duration
        targetColor = originalColor
    }

    func body(content: Content) -> some View {
        content
            .foregroundStyle(targetColor)
            .onReceive(publisher, perform: { newValue in
                switch newValue {
                case .neutral:
                    return
                case .negative:
                    targetColor = negativeColor
                case .positive:
                    targetColor = positiveColor
                }

                withAnimation(.easeInOut(duration: duration)) {
                    targetColor = originalColor
                }
            })
    }
}

extension View {
    func blinkForegroundColor(
        publisher: Published<ForegroundBlinkAnimationModifier.Change>.Publisher,
        positiveColor: Color,
        negativeColor: Color,
        originalColor: Color,
        duration: Double = 0.5
    ) -> some View {
        modifier(
            ForegroundBlinkAnimationModifier(
                publisher: publisher,
                positiveColor: positiveColor,
                negativeColor: negativeColor,
                originalColor: originalColor,
                duration: duration
            )
        )
    }
}

extension ForegroundBlinkAnimationModifier {
    enum Change {
        case neutral
        case positive
        case negative

        static func calculateChange<Value: Comparable & Equatable>(from: Value?, to: Value) -> Change {
            guard let from else {
                return .neutral
            }

            return to == from ? .neutral : to > from ? .positive : .negative
        }
    }
}

private extension ForegroundBlinkAnimationModifier.Change {
    var next: Self {
        switch self {
        case .neutral:
            return .positive
        case .positive:
            return .negative
        case .negative:
            return .neutral
        }
    }
}

#Preview {
    class Blinker: ObservableObject {
        @Published var blink: ForegroundBlinkAnimationModifier.Change = .neutral
    }

    let blinker = Blinker()

    return VStack {
        Button("Blink") {
            blinker.blink = blinker.blink.next
        }

        Text("5.5431254132 BTC")
            .blinkForegroundColor(
                publisher: blinker.$blink,
                positiveColor: Colors.Text.accent,
                negativeColor: Colors.Text.warning,
                originalColor: Colors.Text.primary1,
                duration: 1.0
            )
            .style(Fonts.Regular.footnote, color: Colors.Text.primary1)
    }
    .background(Color.yellow)
}
