//
//  ScrollViewContentOffsetLocker.swift
//  Tangem
//
//  Created by Andrey Fedorov on 11.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import Combine

/// A simple helper with RAII semantics to 'disable' scroll inside `UIScrollView` without using `isScrollEnabled`
/// property and hence without breaking the entire pan gesture.
final class ScrollViewContentOffsetLocker {
    // Strong ref to the scroll view instance is mandatory, because we're using KVO to observe this instance
    let scrollView: UIScrollView

    private(set) var isLocked = false

    private var subscription: AnyCancellable?

    private init(
        scrollView: UIScrollView
    ) {
        self.scrollView = scrollView
        bind()
    }

    deinit {
        // Explicitly stop KVO subscription just in case, to guarantee that KVO subscription won't outlive the KVO target
        subscription?.cancel()
    }

    func lock() {
        #if DEBUG
        dispatchPrecondition(condition: .onQueue(.main))
        #endif // DEBUG
        isLocked = true
    }

    func unlock() {
        #if DEBUG
        dispatchPrecondition(condition: .onQueue(.main))
        #endif // DEBUG
        isLocked = false
    }

    private func bind() {
        subscription = scrollView
            .publisher(for: \.contentOffset)
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { locker, _ in
                #if DEBUG
                dispatchPrecondition(condition: .onQueue(.main))
                #endif // DEBUG

                if locker.isLocked {
                    locker.scrollView.adjustedContentOffset = .zero
                }
            }
    }
}

// MARK: - Convenience extensions

extension ScrollViewContentOffsetLocker {
    static func make(for scrollView: UIScrollView) -> Self {
        return Self(scrollView: scrollView)
    }
}
