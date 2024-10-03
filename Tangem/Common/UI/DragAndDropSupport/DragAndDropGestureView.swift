//
//  DragAndDropGestureView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 10.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

struct DragAndDropGestureView<
    T, U
>: UIViewRepresentable where T: DragAndDropGesturePredicate, U: DragAndDropGestureContextProviding {
    typealias OnLongPressChanged = (_ isRecognized: Bool, _ context: U.Context) -> Void
    typealias OnDragChanged = (_ translation: CGSize, _ context: U.Context) -> Void
    typealias OnEnded = (_ context: U.Context) -> Void
    typealias OnCancel = (_ context: U.Context) -> Void

    var minimumPressDuration: TimeInterval = 0.5 // Same default value as `UILongPressGestureRecognizer` has
    var allowableMovement: CGFloat = 10.0 /// Same default value as `UILongPressGestureRecognizer` has

    var gesturePredicate: T
    var contextProvider: U

    var onLongPressChanged: OnLongPressChanged?
    var onDragChanged: OnDragChanged?
    var onEnded: OnEnded?
    var onCancel: OnCancel?

    func makeCoordinator() -> Coordinator {
        return Coordinator(
            gesturePredicate: gesturePredicate,
            contextProvider: contextProvider,
            onLongPressChanged: onLongPressChanged,
            onDragChanged: onDragChanged,
            onEnded: onEnded,
            onCancel: onCancel
        )
    }

    func makeUIView(context: Context) -> UIView {
        let coordinator = context.coordinator

        let gestureRecognizer = UILongPressGestureRecognizer(
            target: coordinator,
            action: #selector(Coordinator.longPressGestureHandler(_:))
        )
        gestureRecognizer.minimumPressDuration = minimumPressDuration
        gestureRecognizer.allowableMovement = allowableMovement
        gestureRecognizer.delegate = coordinator
        coordinator.gestureRecognizer = gestureRecognizer

        let uiView = UIView()
        uiView.addGestureRecognizer(gestureRecognizer)

        return uiView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        let coordinator = context.coordinator

        coordinator.gesturePredicate = gesturePredicate
        coordinator.contextProvider = contextProvider

        coordinator.onLongPressChanged = onLongPressChanged
        coordinator.onDragChanged = onDragChanged
        coordinator.onEnded = onEnded
        coordinator.onCancel = onCancel

        coordinator.gestureRecognizer?.minimumPressDuration = minimumPressDuration
        coordinator.gestureRecognizer?.allowableMovement = allowableMovement
    }
}

// MARK: - Coordinator

extension DragAndDropGestureView {
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        fileprivate var gesturePredicate: T
        fileprivate var contextProvider: U
        fileprivate weak var gestureRecognizer: UILongPressGestureRecognizer?

        fileprivate var onLongPressChanged: OnLongPressChanged?
        fileprivate var onDragChanged: OnDragChanged?
        fileprivate var onEnded: OnEnded?
        fileprivate var onCancel: OnCancel?

        private var startLocation: CGPoint = .zero

        init(
            gesturePredicate: T,
            contextProvider: U,
            onLongPressChanged: OnLongPressChanged?,
            onDragChanged: OnDragChanged?,
            onEnded: OnEnded?,
            onCancel: OnCancel?
        ) {
            self.gesturePredicate = gesturePredicate
            self.contextProvider = contextProvider
            self.onLongPressChanged = onLongPressChanged
            self.onDragChanged = onDragChanged
            self.onEnded = onEnded
            self.onCancel = onCancel
        }

        // MARK: - Gesture handlers

        @objc
        fileprivate func longPressGestureHandler(_ gestureRecognizer: UILongPressGestureRecognizer) {
            let context = contextProvider.makeContext(from: gestureRecognizer)

            switch gestureRecognizer.state {
            case .began:
                startLocation = gestureRecognizer.location(in: nil)
                onLongPressChanged?(true, context)
            case .changed:
                let currentLocation = gestureRecognizer.location(in: nil)
                let translation = CGSize(
                    width: currentLocation.x - startLocation.x,
                    height: currentLocation.y - startLocation.y
                )
                onDragChanged?(translation, context)
            case .ended:
                onEnded?(context)
            case .cancelled:
                onCancel?(context)
            case .possible, .failed:
                break
            @unknown default:
                assertionFailure("Unknown state received \(gestureRecognizer.state)")
            }
        }

        // MARK: - UIGestureRecognizerDelegate protocol conformance

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldReceive touch: UITouch
        ) -> Bool {
            if gesturePredicate.gestureRecognizer(gestureRecognizer, shouldReceive: touch) {
                let context = contextProvider.makeContext(from: gestureRecognizer)
                onLongPressChanged?(false, context)

                return true
            }

            return false
        }
    }
}
