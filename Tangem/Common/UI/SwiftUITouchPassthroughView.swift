//
//  SwiftUITouchPassthroughView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 29.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

struct SwiftUITouchPassthroughView: UIViewRepresentable {
    typealias ShouldPassthrough = (_ point: CGPoint, _ event: UIEvent?) -> Bool

    let shouldPassthrough: ShouldPassthrough

    func makeUIView(context: Context) -> TouchPassthroughView {
        let uiView = TouchPassthroughView()
        uiView.delegate = context.coordinator
        return uiView
    }

    func updateUIView(_ uiView: TouchPassthroughView, context: Context) {
        context.coordinator.shouldPassthrough = shouldPassthrough
    }

    func makeCoordinator() -> TouchPassthroughViewCoordinator {
        return TouchPassthroughViewCoordinator(shouldPassthrough: shouldPassthrough)
    }
}

// MARK: - Auxiliary types

extension SwiftUITouchPassthroughView {
    final class TouchPassthroughViewCoordinator: TouchPassthroughViewDelegate {
        fileprivate var shouldPassthrough: ShouldPassthrough

        fileprivate init(shouldPassthrough: @escaping ShouldPassthrough) {
            self.shouldPassthrough = shouldPassthrough
        }

        func touchPassthroughView(
            _ passthroughView: TouchPassthroughView,
            shouldPassthroughTouchAt point: CGPoint,
            with event: UIEvent?
        ) -> Bool {
            return shouldPassthrough(point, event)
        }
    }
}
