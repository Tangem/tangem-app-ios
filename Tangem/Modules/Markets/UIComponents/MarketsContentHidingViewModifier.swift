//
//  MarketsContentHidingViewModifier.swift
//  Tangem
//
//  Created by Andrey Fedorov on 30.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsContentHidingViewModifier: ViewModifier {
    @State private var progress: CGFloat

    private var viewOpacity: CGFloat { progress.interpolatedProgress(inRange: 0.0 ... 0.2) }

    init(initialProgress: CGFloat = .zero) {
        _progress = .init(initialValue: initialProgress)
    }

    func body(content: Content) -> some View {
        content
            .opacity(viewOpacity)
            .animation(.easeInOut(duration: 0.2), value: viewOpacity)
            .onOverlayContentProgressChange { progress = $0 }
    }
}
