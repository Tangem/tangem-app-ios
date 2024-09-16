//
//  SwiftUIGestureConflictResolver.swift
//  Tangem
//
//  Created by Andrey Fedorov on 15.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

final class SwiftUIGestureConflictResolver {
    private let handledSwiftUIGestures: NSHashTable<UIGestureRecognizer> = .weakObjects()
    private var isUIKitGestureStarted = false

    deinit {
        onUIKitGestureEnd()
    }

    func handleSwiftUIGestureIfNeeded(_ gestureRecognizer: UIGestureRecognizer) {
        guard
            !isUIKitGestureStarted,
            gestureRecognizer.isFromSwiftUI,
            gestureRecognizer.isEnabled
        else {
            return
        }

        handledSwiftUIGestures.add(gestureRecognizer)
    }

    func onUIKitGestureStart() {
        guard !isUIKitGestureStarted else {
            return
        }

        handledSwiftUIGestures.allObjects.forEach { $0.isEnabled = false }
        isUIKitGestureStarted = true
    }

    func onUIKitGestureEnd() {
        handledSwiftUIGestures.allObjects.forEach { $0.isEnabled = true }
        handledSwiftUIGestures.removeAllObjects()
        isUIKitGestureStarted = false
    }
}

// MARK: - Convenience extensions

private extension UIGestureRecognizer {
    var isFromSwiftUI: Bool {
        let className = NSStringFromClass(Self.self).lowercased()

        return className.contains("swiftui") || className.contains("uikitgesturerecognizer")
    }
}
