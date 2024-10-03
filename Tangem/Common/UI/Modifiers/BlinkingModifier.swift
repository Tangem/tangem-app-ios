//
//  BlinkingModifier.swift
//  Tangem
//
//  Created by Andrew Son on 24/06/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct BlinkingModifier: ViewModifier {
    let publisher: Published<Bool>.Publisher
    let originalColor: Color
    let color: Color
    let duration: Double

    @State var targetColor: Color = .clear
    @State private var item: DispatchWorkItem? = nil

    init(publisher: Published<Bool>.Publisher, originalColor: Color, color: Color, duration: Double) {
        self.publisher = publisher
        self.originalColor = originalColor
        self.color = color
        self.duration = duration
        targetColor = originalColor
    }

    func body(content: Content) -> some View {
        content
            .foregroundColor(.white)
            .colorMultiply(targetColor)
            .onReceive(publisher, perform: { newValue in
                item?.cancel()
                withAnimation(.easeOut(duration: duration)) {
                    targetColor = newValue ? color : originalColor
                }
                item = DispatchWorkItem(block: {
                    withAnimation(.easeOut(duration: duration)) {
                        targetColor = originalColor
                    }
                })
                DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: item!)
            })
    }
}

extension View {
    func blink(
        publisher: Published<Bool>.Publisher,
        originalColor: Color,
        color: Color,
        duration: Double = 0.5
    ) -> some View {
        modifier(BlinkingModifier(
            publisher: publisher,
            originalColor: originalColor,
            color: color,
            duration: duration
        ))
    }
}
