//
//  BottomScrollableSheetStateObject.swift
//  Tangem
//
//  Created by Sergey Balashov on 01.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit
import Combine

final class BottomScrollableSheetStateObject: ObservableObject {
    @Published var scrollViewIsDragging: Bool = false

    @Published var visibleHeight: CGFloat = .zero

    var headerHeight: CGFloat = .zero {
        didSet {
            if oldValue != headerHeight {
                updateToState(state)
            }
        }
    }

    var geometryInfoSubject: some Subject<GeometryInfo, Never> { _geometryInfoSubject }
    private let _geometryInfoSubject = CurrentValueSubject<GeometryInfo, Never>(.zero)
    private var geometryInfo: GeometryInfo { _geometryInfoSubject.value }

    var contentOffsetSubject: some Subject<CGPoint, Never> { _contentOffsetSubject }
    private let _contentOffsetSubject = CurrentValueSubject<CGPoint, Never>(.zero)
    private var contentOffset: CGPoint { _contentOffsetSubject.value }

    var progress: CGFloat {
        let maxHeight = height(for: .top)
        let minHeight = height(for: .bottom)
        let progress = (visibleHeight - minHeight) / (maxHeight - minHeight)
        return clamp(progress, min: 0.0, max: 1.0)
    }

    var scale: CGFloat {
        let minScale = 1.0
        let maxScale = sourceViewMinHeight / sourceViewMaxHeight
        return minScale - (minScale - maxScale) * progress
    }

    private(set) var state: SheetState = .bottom

    private var sourceViewMaxHeight: CGFloat { UIScreen.main.bounds.height }
    private var sourceViewMinHeight: CGFloat { height(for: .top) + Constants.sheetTopInset }

    func onAppear() {
        updateToState(state)
    }

    func onHeaderTap() {
        updateToState(.top)
    }

    /// Use for set and update sheet to the state
    private func updateToState(_ state: SheetState) {
        self.state = state

        withAnimation(.easeOut) {
            visibleHeight = height(for: state)
            // TODO: Andrey Fedorov - Implement status bar style management (IOS-4770)
        }
    }

    /// Use for change height when user is dragging
    private func updateVisibleHeight(_ height: CGFloat) {
        withAnimation(.interactiveSpring()) {
            self.visibleHeight = height
        }
    }

    private func height(for state: BottomScrollableSheetStateObject.SheetState) -> CGFloat {
        switch state {
        case .bottom:
            return headerHeight
        case .top:
            return geometryInfo.size.height + geometryInfo.safeAreaInsets.bottom - Constants.sheetTopInset
        }
    }

    // MARK: Gestures

    func headerDragGesture(onChanged value: DragGesture.Value) {
        UIApplication.shared.endEditing()
        dragView(translation: value.translation.height)
    }

    func headerDragGesture(onEnded value: DragGesture.Value) {
        let hidingLine = height(for: .top) * Constants.hidingLineMultiplicator

        // If the ended location below the hiding line
        if value.predictedEndLocation.y > hidingLine {
            updateToState(.bottom)
        } else {
            updateToState(.top)
        }
    }

    func scrollViewContentDragGesture(onChanged value: UIPanGestureRecognizer.Value) {
        UIApplication.shared.endEditing()

        let translationChange = value.translation.height
        let isFromTop = contentOffset.y <= .zero
        let isBottomDirection = translationChange > .zero
        if isFromTop, isBottomDirection, !scrollViewIsDragging {
            scrollViewIsDragging = true
        }

        if scrollViewIsDragging {
            dragView(translation: translationChange)
        }
    }

    func scrollViewContentDragGesture(onEnded value: UIPanGestureRecognizer.Value) {
        // If the dragging was started from the top of the ScrollView
        if contentOffset.y <= .zero {
            // The user made a quick enough swipe to hide sheet
            let isHighVelocity = value.velocity.y > geometryInfo.size.height

            // The user stop swipe below hiding line
            let hidingLine = height(for: .top) * Constants.hidingLineMultiplicator
            let isStoppedBelowHidingLine = visibleHeight < hidingLine

            if isHighVelocity || isStoppedBelowHidingLine {
                updateToState(.bottom)
            } else {
                updateToState(.top)
            }
        }

        if scrollViewIsDragging {
            scrollViewIsDragging = false
        }
    }

    private func dragView(translation: CGFloat) {
        var translationChange = translation

        switch state {
        case .top:
            // For the top state reduce the direction to bottom
            if translationChange < .zero {
                translationChange /= Constants.reduceSwipeMultiplicator
            }
        case .bottom:
            // For the bottom state reduce the direction to top
            if translationChange > .zero {
                translationChange /= Constants.reduceSwipeMultiplicator
            }
        }

        let newHeight = height(for: state) - translationChange
        updateVisibleHeight(newHeight)
    }
}

// MARK: - Auxiliary types

extension BottomScrollableSheetStateObject {
    enum SheetState: String, Hashable {
        case top
        case bottom

        var isBottom: Bool { self == .bottom }
    }
}

// MARK: - Constants

private extension BottomScrollableSheetStateObject {
    enum Constants {
        static let hidingLineMultiplicator: CGFloat = 0.5
        static let reduceSwipeMultiplicator: CGFloat = 10.0
        static let sheetTopInset: CGFloat = 16.0
    }
}
