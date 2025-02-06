//
//  StoriesViewModel.swift
//  StoriesDemo
//
//  Created by Andrey Chukavin on 26.01.2022.
//

import Foundation
import Combine
import SwiftUI

class StoriesViewModel: ObservableObject {
    @Injected(\.promotionService) var promotionService: PromotionServiceProtocol

    @Published var currentPage: WelcomeStoryPage = .meetTangem
    @Published var currentProgress = 0.0
    @Published var checkingPromotionAvailability = true
    @Published var isScanning = false

    var currentPageIndex: Int {
        pages.firstIndex(of: currentPage) ?? 0
    }

    private(set) var pages: [WelcomeStoryPage] = []
    private var timerSubscription: AnyCancellable?
    private var timerStartDate: Date?
    private var longTapTimerSubscription: AnyCancellable?
    private var longTapDetected = false
    private var currentDragLocation: CGPoint?
    private var bag: Set<AnyCancellable> = []

    private var showLearnPage: Bool = false
    private let longTapDuration = 0.25
    private let minimumSwipeDistance = 100.0
    private let promotionCheckTimeout: TimeInterval = 5
    private var shouldStartTimer: Bool = true

    weak var delegate: StoriesDelegate?

    deinit {
        AppLogger.debug(self)
    }

    func setDelegate(delegate: StoriesDelegate) {
        self.delegate = delegate

        self.delegate?.isScanning
            .assign(to: \.isScanning, on: self, ownership: .weak)
            .store(in: &bag)
    }

    func setLifecyclePublisher(publisher: AnyPublisher<Bool, Never>) {
        publisher
            .delay(for: 0.5, scheduler: DispatchQueue.main) // to fix issue with no-opening of tokens search
            .sink { [weak self] viewDismissed in
                guard let self else { return }

                if viewDismissed {
                    becomeActive()
                } else {
                    resignActive()
                }
            }
            .store(in: &bag)
    }

    func checkPromotion() async {
        let isNewCard = true
        let userWalletId: String? = nil
        await promotionService.checkPromotion(isNewCard: isNewCard, userWalletId: userWalletId, timeout: promotionCheckTimeout)
        await didFinishCheckingPromotion()
    }

    func onAppear() {
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.pauseTimer()
            }
            .store(in: &bag)

        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                if viewModel.shouldStartTimer {
                    viewModel.resumeTimer()
                }
            }
            .store(in: &bag)

        if shouldStartTimer {
            DispatchQueue.main.async {
                self.restartTimer()
            }
        }
    }

    func onDisappear() {
        pauseTimer()
    }

    func didDrag(_ current: CGPoint) {
        if longTapDetected {
            return
        }

        if let currentDragLocation = currentDragLocation, currentDragLocation.distance(to: current) < minimumSwipeDistance {
            return
        }

        currentDragLocation = current
        pauseTimer()

        longTapTimerSubscription = Timer.publish(every: longTapDuration, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in
                self?.currentDragLocation = nil
                self?.longTapTimerSubscription = nil
                self?.longTapDetected = true
            }
    }

    func didEndDrag(_ current: CGPoint, destination: CGPoint, viewWidth: CGFloat) {
        if let currentDragLocation = currentDragLocation {
            let distance = (destination.x - current.x)

            let moveForward: Bool
            if abs(distance) < minimumSwipeDistance {
                moveForward = currentDragLocation.x > viewWidth / 2
            } else {
                moveForward = distance > 0
            }

            move(forward: moveForward)
        } else {
            resumeTimer()
        }

        currentDragLocation = nil
        longTapTimerSubscription = nil
        longTapDetected = false
    }

    @MainActor
    private func didFinishCheckingPromotion() {
        showLearnPage = promotionService.promotionAvailable

        var pages: [WelcomeStoryPage] = WelcomeStoryPage.allCases
        if !showLearnPage,
           let learnIndex = pages.firstIndex(of: .learn) {
            pages.remove(at: learnIndex)
        }

        self.pages = pages

        currentPage = pages[0]

        checkingPromotionAvailability = false
    }

    private func move(forward: Bool) {
        guard let currentPageIndex = pages.firstIndex(of: currentPage) else { return }

        let nextPageIndex = currentPageIndex + (forward ? 1 : -1)

        let nextPage: WelcomeStoryPage
        if nextPageIndex < 0 || nextPageIndex > (pages.count - 1) {
            nextPage = pages.first!
        } else {
            nextPage = pages[nextPageIndex]
        }

        currentPage = nextPage
        restartTimer()
    }

    private func timerIsRunning() -> Bool {
        timerSubscription != nil
    }

    private func restartTimer() {
        currentProgress = 0
        resumeTimer()
    }

    private func pauseTimer() {
        let now = Date()

        let elapsedTime: TimeInterval
        if let timerStartDate = timerStartDate {
            elapsedTime = now.timeIntervalSince(timerStartDate)
        } else {
            elapsedTime = 0
        }

        let progress = elapsedTime / currentPage.duration

        timerSubscription = nil

        withAnimation(.linear(duration: 0)) { [weak self] in
            self?.currentProgress = progress
        }
    }

    private func resumeTimer() {
        if timerIsRunning() {
            return
        }

        let remainingProgress = 1 - currentProgress
        let remainingStoryDuration = currentPage.duration * remainingProgress
        let currentStoryTime = currentPage.duration * currentProgress

        timerStartDate = Date() - TimeInterval(currentStoryTime)

        withAnimation(.linear(duration: remainingStoryDuration)) { [weak self] in
            self?.currentProgress = 1
        }

        timerSubscription = Timer.publish(every: remainingStoryDuration, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in
                self?.timerSubscription = nil
                self?.move(forward: true)
            }
    }
}

extension StoriesViewModel: WelcomeViewLifecycleListener {
    func resignActive() {
        if timerIsRunning() {
            pauseTimer()
        } else {
            // First start of the app with welcome onboarding
            shouldStartTimer = false
        }
    }

    func becomeActive() {
        shouldStartTimer = true

        if !timerIsRunning() {
            resumeTimer()
        }
    }
}

private extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        return sqrt(pow(x - other.x, 2) + pow(y - other.y, 2))
    }
}
