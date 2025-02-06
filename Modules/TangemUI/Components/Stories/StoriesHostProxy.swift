//
//  StoriesHostProxy.swift
//  TangemModules
//
//  Created by Aleksei Lobankov on 04.02.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

/// Utility class that provides some functionality over stories host view.
public final class StoriesHostProxy {
    private let pauseVisibleStoryAction: () -> Void
    private let resumeVisibleStoryAction: () -> Void

    init(pauseVisibleStoryAction: @escaping () -> Void, resumeVisibleStoryAction: @escaping () -> Void) {
        self.pauseVisibleStoryAction = pauseVisibleStoryAction
        self.resumeVisibleStoryAction = resumeVisibleStoryAction
    }

    public func pauseVisibleStory() {
        pauseVisibleStoryAction()
    }

    public func resumeVisibleStory() {
        resumeVisibleStoryAction()
    }
}
