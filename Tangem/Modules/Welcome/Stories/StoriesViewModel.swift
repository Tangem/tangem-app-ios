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
    @Published var currentPage: WelcomeStoryPage = WelcomeStoryPage.allCases[0]
    @Published var currentProgress = 0.0

    let pages: [WelcomeStoryPage] = WelcomeStoryPage.allCases
    private var timerSubscription: AnyCancellable?
    private var timerStartDate: Date?
    private var longTapTimerSubscription: AnyCancellable?
    private var longTapDetected = false
    private var currentDragLocation: CGPoint?
    private var bag: Set<AnyCancellable> = []

    private let longTapDuration = 0.25
    private let minimumSwipeDistance = 100.0

    func onAppear() {
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.pauseTimer()
            }
            .store(in: &bag)

        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.resumeTimer()
            }
            .store(in: &bag)

        DispatchQueue.main.async {
            self.restartTimer()
        }
    }

    func onDisappear() {
        pauseTimer()
        bag = []
    }

    @ViewBuilder
    func currentStoryPage(
        isScanning: Binding<Bool>,
        scanCard: @escaping () -> Void,
        orderCard: @escaping () -> Void,
        searchTokens: @escaping () -> Void
    ) -> some View {
        let progressBinding = Binding<Double> { [weak self] in
            self?.currentProgress ?? 0
        } set: { [weak self] in
            self?.currentProgress = $0
        }

        switch currentPage {
        case WelcomeStoryPage.meetTangem:
            MeetTangemStoryPage(progress: progressBinding, immediatelyShowButtons: AppSettings.shared.didDisplayMainScreenStories, isScanning: isScanning, scanCard: scanCard, orderCard: orderCard)
        case WelcomeStoryPage.awe:
            AweStoryPage(progress: progressBinding, isScanning: isScanning, scanCard: scanCard, orderCard: orderCard)
        case WelcomeStoryPage.backup:
            BackupStoryPage(progress: progressBinding, isScanning: isScanning, scanCard: scanCard, orderCard: orderCard)
        case WelcomeStoryPage.currencies:
            CurrenciesStoryPage(progress: progressBinding, isScanning: isScanning, scanCard: scanCard, orderCard: orderCard, searchTokens: searchTokens)
//        case WelcomeStoryPage.web3:
//            Web3StoryPage(progress: progressBinding, isScanning: isScanning, scanCard: scanCard, orderCard: orderCard)
        case WelcomeStoryPage.finish:
            FinishStoryPage(progress: progressBinding, isScanning: isScanning, scanCard: scanCard, orderCard: orderCard)
        }
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

        longTapTimerSubscription = Timer.publish(every: longTapDuration, on: RunLoop.main, in: .default)
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

    private func move(forward: Bool) {
        currentPage = WelcomeStoryPage(rawValue: currentPage.rawValue + (forward ? 1 : -1)) ?? pages.first!
        restartTimer()
        if currentPage != pages.first {
            AppSettings.shared.didDisplayMainScreenStories = true
        }
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
    func resignActve() {
        if timerIsRunning() {
            pauseTimer()
        }
    }

    func becomeActive() {
        if !timerIsRunning() {
            resumeTimer()
        }
    }
}

fileprivate extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        return sqrt(pow(x - other.x, 2) + pow(y - other.y, 2))
    }
}
