//
//  StoryViewModel.swift
//  TangemModules
//
//  Created by Aleksei Lobankov on 30.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation

@MainActor
final class StoryViewModel: ObservableObject {
    private let pagesCount: Int
    private let pageDuration: TimeInterval

    private var visiblePageProgress: CGFloat = 0
    private var canHandleUIInteractions = true
    private var isPresented = false

    private lazy var timer = Timer.publish(every: Constants.timerTickDuration, on: .main, in: .common).autoconnect()
    private var timerCancellable: (any Cancellable)?

    private let storyTransitionSubject: PassthroughSubject<StoryTransition, Never>

    private var timerIsRunning: Bool {
        timerCancellable != nil
    }

    private var storyHasFurtherPages: Bool {
        visiblePageIndex < pagesCount - 1
    }

    let storyTransitionPublisher: AnyPublisher<StoryTransition, Never>

    @Published private(set) var visiblePageIndex: Int

    init(pagesCount: Int, pageDuration: TimeInterval = 2.5) {
        assert(pagesCount > 0, "Expected to have at least one page. Developer mistake")

        self.pagesCount = pagesCount
        self.pageDuration = pageDuration
        visiblePageIndex = 0

        storyTransitionSubject = PassthroughSubject()
        storyTransitionPublisher = storyTransitionSubject.eraseToAnyPublisher()
    }

    // MARK: - Internal methods

    func handle(viewEvent: StoryViewEvent) {
        switch viewEvent {
        case .viewDidAppear:
            handleViewDidAppear()

        case .viewDidDisappear:
            handleViewDidDisappear()

        case .viewInteractionPaused:
            handleViewInteractionPaused()

        case .viewInteractionResumed:
            handleViewInteractionResumed()

        case .longTapPressed:
            handleLongTapPressed()

        case .longTapEnded:
            handleLongTapEnded()

        case .tappedForward:
            handleTappedForward()

        case .tappedBackward:
            handleTappedBackward()

        case .willTransitionBackFromOtherStory:
            handleWillTransitionBackFromOtherStory()
        }
    }

    func pageProgress(for index: Int) -> CGFloat {
        if index < visiblePageIndex {
            return 1
        } else if index == visiblePageIndex {
            return visiblePageProgress
        } else {
            return 0
        }
    }

    // MARK: - Private methods

    private func startTimer() {
        timerCancellable = timer
            .sink { [weak self] _ in
                guard let self else { return }

                let reachedLastPage = visiblePageIndex >= pagesCount - 1
                let reachedFullPageProgress = visiblePageProgress >= 1

                if reachedLastPage, reachedFullPageProgress {
                    stopTimer()
                    storyTransitionSubject.send(.forward)
                    return
                }

                incrementProgressFromTimer()
            }
    }

    private func stopTimer() {
        timerCancellable = nil
        timer.upstream.connect().cancel()
    }

    private func incrementProgressFromTimer() {
        defer { objectWillChange.send() }

        let incrementedProgressValue = visiblePageProgress + Constants.timerTickDuration / pageDuration
        let maxProgressValue = 1.0

        guard incrementedProgressValue > maxProgressValue else {
            visiblePageProgress = incrementedProgressValue
            return
        }

        if storyHasFurtherPages {
            visiblePageIndex += 1
            visiblePageProgress = 0
        } else {
            visiblePageProgress = maxProgressValue
        }
    }
}

// MARK: - View events handling

extension StoryViewModel {
    private func handleViewDidAppear() {
        isPresented = true

        if visiblePageProgress > Constants.appearancePageProgressThreshold {
            visiblePageProgress = Constants.appearanceAdjustedPageProgress
            objectWillChange.send()
        }

        startTimer()
    }

    private func handleViewDidDisappear() {
        isPresented = false
        stopTimer()
    }

    private func handleViewInteractionPaused() {
        canHandleUIInteractions = false
        stopTimer()
    }

    private func handleViewInteractionResumed() {
        canHandleUIInteractions = true

        if isPresented {
            startTimer()
        }
    }

    private func handleLongTapPressed() {
        guard canHandleUIInteractions else { return }
        stopTimer()
    }

    private func handleLongTapEnded() {
        guard canHandleUIInteractions else { return }
        startTimer()
    }

    private func handleTappedForward() {
        guard canHandleUIInteractions else { return }

        if !timerIsRunning {
            startTimer()
        }

        guard storyHasFurtherPages else {
            storyTransitionSubject.send(.forward)
            return
        }

        visiblePageIndex += 1
        visiblePageProgress = 0
    }

    private func handleTappedBackward() {
        guard canHandleUIInteractions else { return }

        if !timerIsRunning {
            startTimer()
        }

        guard visiblePageIndex > 0 else {
            visiblePageProgress = 0
            storyTransitionSubject.send(.backward)
            return
        }

        visiblePageIndex -= 1
        let progressToUpdate = visiblePageProgress - Constants.extraProgressForPageBackMovement
        visiblePageProgress = max(0, progressToUpdate)
    }

    private func handleWillTransitionBackFromOtherStory() {
        visiblePageProgress = 0
        objectWillChange.send()
    }
}

// MARK: - Nested types

extension StoryViewModel {
    enum StoryTransition {
        case forward
        case backward
    }

    private enum Constants {
        /// 0.05
        static let timerTickDuration: TimeInterval = 0.05
        /// 0.6
        static let appearancePageProgressThreshold: CGFloat = 0.6
        /// 0.2
        static let appearanceAdjustedPageProgress: CGFloat = 0.2
        /// 0.2
        static let extraProgressForPageBackMovement: CGFloat = 0.2
    }
}
