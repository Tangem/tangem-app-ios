//
//  StoriesHostViewModel.swift
//  TangemModules
//
//  Created by Aleksei Lobankov on 30.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Dispatch

@MainActor
final class StoriesHostViewModel: ObservableObject {
    private let storyViewModels: [StoryViewModel]
    private var cancellables = Set<AnyCancellable>()

    @Published var visibleStoryIndex: Int
    @Published private(set) var allowsHitTesting = true
    @Published private(set) var isPresented = true

    init(storyViewModels: [StoryViewModel], visibleStoryIndex: Int = 0) {
        assert(visibleStoryIndex < storyViewModels.count)

        self.storyViewModels = storyViewModels
        self.visibleStoryIndex = visibleStoryIndex

        subscribeToStoriesTransitionEvents()
    }

    func pauseVisibleStory() {
        storyViewModels[visibleStoryIndex].handle(viewEvent: .viewInteractionPaused)
    }

    func resumeVisibleStory() {
        storyViewModels[visibleStoryIndex].handle(viewEvent: .viewInteractionResumed)
    }

    private func subscribeToStoriesTransitionEvents() {
        storyViewModels
            .enumerated()
            .forEach { index, viewModel in
                viewModel.storyTransitionPublisher
                    .sink { [weak self] transition in
                        self?.handleStoryTransition(index, transition: transition)
                    }
                    .store(in: &cancellables)
            }
    }

    private func handleStoryTransition(_ index: Int, transition: StoryViewModel.StoryTransition) {
        switch transition {
        case .forward:
            guard index < storyViewModels.count - 1 else {
                isPresented = false
                return
            }
            updateVisibleStory(index: index + 1)

        case .backward:
            guard index > 0 else { return }
            let previousStoryViewModelIndex = index - 1
            storyViewModels[previousStoryViewModelIndex].handle(viewEvent: .willTransitionBackFromOtherStory)
            updateVisibleStory(index: previousStoryViewModelIndex)
        }
    }

    private func updateVisibleStory(index: Int) {
        allowsHitTesting = false
        visibleStoryIndex = index

        // @alobankov, prevents mid-transition break when user taps faster than animation duration.
        Task {
            try? await Task.sleep(nanoseconds: Constants.storyTransitionDuration)
            allowsHitTesting = true
        }
    }
}

extension StoriesHostViewModel {
    private enum Constants {
        static let storyTransitionDuration: UInt64 = 35 * NSEC_PER_SEC / 100
    }
}
