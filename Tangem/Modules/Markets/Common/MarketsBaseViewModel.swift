//
//  MarketsBaseViewModel.swift
//  Tangem
//
//  Created by Andrey Fedorov on 11.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import func SwiftUI.withAnimation

class MarketsBaseViewModel: ObservableObject {
    /// For unknown reasons, the `@self` and `@identity` of our view change when push navigation is performed in other
    /// navigation controllers in the application (on the main screen for example), which causes the state of
    /// this property to be lost if it were stored in the view as a `@State` variable.
    /// Therefore, we store it here in the view model as the `@Published` property instead of storing it in a view.
    @Published private(set) var overlayContentProgress: CGFloat

    var overlayContentHidingProgress: CGFloat {
        overlayContentProgress.interpolatedProgress(inRange: Constants.overlayContentHidingProgressInterpolationRange)
    }

    var isNavigationBarBackgroundBackdropViewHidden: Bool {
        1.0 - overlayContentHidingProgress <= .ulpOfOne
    }

    init(
        overlayContentProgressInitialValue: CGFloat
    ) {
        precondition(type(of: self) != MarketsBaseViewModel.self, "Abstract class")

        _overlayContentProgress = .init(initialValue: overlayContentProgressInitialValue)
    }

    func onOverlayContentProgressChange(_ progress: CGFloat) {
        withAnimation(.easeInOut(duration: Constants.overlayContentHidingAnimationDuration)) {
            overlayContentProgress = progress
        }
    }
}

// MARK: - Constants

private extension MarketsBaseViewModel {
    enum Constants {
        static let overlayContentHidingProgressInterpolationRange: ClosedRange<CGFloat> = 0.0 ... 0.2
        static let overlayContentHidingAnimationDuration: TimeInterval = 0.2
    }
}
