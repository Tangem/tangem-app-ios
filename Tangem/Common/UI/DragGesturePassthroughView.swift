//
//  DragGesturePassthroughView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 03.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

/// Usage example below:
/// ```
/// struct SomeView: View {
///     var body: some View {
///         ScrollView {
///             ZStack {
///                 DragGesturePassthroughView(
///                     onChanged: { value in
///                         // Handle pan gesture change
///                     },
///                     onEnded: { value in
///                         // Handle pan gesture end
///                     }
///                 )
///
///                 LazyVStack() {
///                     // Some scrollable content
///                 }
///                 .layoutPriority(1000.0)
///             }
///         }
///     }
/// }
/// ```
struct DragGesturePassthroughView: UIViewRepresentable {
    typealias Callback = (UIPanGestureRecognizer.Value) -> Void

    let onChanged: Callback
    let onEnded: Callback

    func makeCoordinator() -> DragGesturePassthroughView.Coordinator {
        return Coordinator(onChanged: onChanged, onEnded: onEnded)
    }

    func makeUIView(context: UIViewRepresentableContext<DragGesturePassthroughView>) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        let dragGestureRecognizer = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.gestureRecognizerPanned)
        )
        dragGestureRecognizer.delegate = context.coordinator
        view.addGestureRecognizer(dragGestureRecognizer)

        return view
    }

    func updateUIView(
        _ uiView: UIView,
        context: UIViewRepresentableContext<DragGesturePassthroughView>
    ) {}
}

// MARK: - Coordinator

extension DragGesturePassthroughView {
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private let onChanged: Callback
        private let onEnded: Callback
        private var startLocation = CGPoint.zero

        init(
            onChanged: @escaping Callback,
            onEnded: @escaping Callback
        ) {
            self.onChanged = onChanged
            self.onEnded = onEnded
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            return true
        }

        @objc
        func gestureRecognizerPanned(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view else {
                assertionFailure("Can't get a view for \(objectDescription(gesture))")
                return
            }

            switch gesture.state {
            case .possible, .cancelled, .failed:
                break
            case .began:
                startLocation = gesture.location(in: view)
            case .changed:
                let value = UIPanGestureRecognizer.Value(
                    time: Date(),
                    location: gesture.location(in: view),
                    startLocation: startLocation,
                    velocity: gesture.velocity(in: view)
                )
                onChanged(value)
            case .ended:
                let value = UIPanGestureRecognizer.Value(
                    time: Date(),
                    location: gesture.location(in: view),
                    startLocation: startLocation,
                    velocity: gesture.velocity(in: view)
                )
                onEnded(value)
            @unknown default:
                break
            }
        }
    }
}
