//
//  ScrollDetector.swift
//  Tangem
//
//  Created by Andrey Fedorov on 03.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class ScrollDetector: ObservableObject {
    /// Returns true when ANY scroll view in the view hierarchy performs ONE of the following actions:
    /// tracking (`UIScrollView.isTracking`), dragging (`UIScrollView.isDragging`) or decelerating (`UIScrollView.isDecelerating`)
    ///
    /// In other words, `ScrollDetector.isScrolling = UIScrollView.isTracking || UIScrollView.isDragging || UIScrollView.isDecelerating`.
    @Published var isScrolling = false

    private var observedRunLoopActivities: CFRunLoopActivity { [.entry, .exit] }
    private var observedRunLoopMode: CFRunLoopMode { RunLoop.Mode.tracking.toCFRef() }

    private lazy var runLoopTrackingObserver: CFRunLoopObserver = CFRunLoopObserverCreateWithHandler(
        kCFAllocatorDefault,
        observedRunLoopActivities.rawValue,
        true,
        0
    ) { [weak self] _, runLoopActivity in
        self?.isScrolling = runLoopActivity == .entry
    }

    deinit {
        runLoopTrackingObserverPrecondition()
    }

    /// Expected to be called in SwiftUI `onAppear` callback.
    func startDetectingScroll() {
        CFRunLoopAddObserver(
            CFRunLoopGetMain(),
            runLoopTrackingObserver,
            observedRunLoopMode
        )
    }

    /// Expected to be called in SwiftUI `onDisappear` callback.
    func stopDetectingScroll() {
        CFRunLoopRemoveObserver(
            CFRunLoopGetMain(),
            runLoopTrackingObserver,
            observedRunLoopMode
        )
    }

    private func runLoopTrackingObserverPrecondition() {
        let isRunLoopTrackingObserverActive = CFRunLoopContainsObserver(
            CFRunLoopGetMain(),
            runLoopTrackingObserver,
            observedRunLoopMode
        )

        assert(
            !isRunLoopTrackingObserverActive,
            "Instance \(self) is about to be deallocated without stopping active scroll detection, that's illegal"
        )
    }
}

// MARK: - Convenience extensions

private extension RunLoop.Mode {
    func toCFRef() -> CFRunLoopMode {
        return CFRunLoopMode(rawValue: rawValue as CFString)
    }
}
