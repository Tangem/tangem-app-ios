//
//  CardsInfoPagerContentSwitchingModifier.swift
//  Tangem
//
//  Created by Andrey Fedorov on 18.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

/// This animator is responsible for changing the `content` part of the pager view based
/// on the active animation direction and progress.
struct CardsInfoPagerContentSwitchingModifier: AnimatableModifier {
    enum PreferenceKey: SwiftUI.PreferenceKey {
        static var defaultValue: Int { .zero }

        static func reduce(value: inout Int, nextValue: () -> Int) {
            value = nextValue()
        }
    }

    var progress: CGFloat
    let finalPageSwitchProgress: CGFloat
    let initialSelectedIndex: Int
    let finalSelectedIndex: Int

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    private var targetIndex: Int {
        let pageSwitchThresholdHasBeenExceeded = finalPageSwitchProgress > 0.5

        if pageSwitchThresholdHasBeenExceeded {
            // Successfull navigation to the next/previous page
            return progress > 0.5 ? finalSelectedIndex : initialSelectedIndex
        } else {
            // Page switch threshold hasn't been exceeded, restoring previously selected page
            return progress > 0.5 ? initialSelectedIndex : finalSelectedIndex
        }
    }

    func body(content: Content) -> some View {
        content
            .preference(key: PreferenceKey.self, value: targetIndex)
    }
}
