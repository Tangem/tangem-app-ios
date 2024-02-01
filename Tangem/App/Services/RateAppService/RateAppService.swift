//
//  RateAppService.swift
//  Tangem
//
//  Created by Andrey Fedorov on 07.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class RateAppService {
    var rateAppAction: AnyPublisher<RateAppAction, Never> { rateAppActionSubject.eraseToAnyPublisher() }

    @AppStorageCompat(StorageKeys.systemReviewPromptRequestDates)
    private var systemReviewPromptRequestDates: [Date] = []

    @AppStorageCompat(StorageKeys.lastRequestedReviewDate)
    private var lastRequestedReviewDate: Date = .distantPast

    @AppStorageCompat(StorageKeys.lastRequestedReviewLaunchCount)
    private var lastRequestedReviewLaunchCount: Int = 0

    @AppStorageCompat(StorageKeys.userDismissedLastRequestedReview)
    private var userDismissedLastRequestedReview: Bool = false

    private var positiveBalanceAppearanceDate: Date? {
        get { AppSettings.shared.positiveBalanceAppearanceDate }
        set { AppSettings.shared.positiveBalanceAppearanceDate = newValue }
    }

    private var currentLaunchCount: Int { AppSettings.shared.numberOfLaunches }

    private var requiredNumberOfLaunches: Int {
        return userDismissedLastRequestedReview
            ? Constants.dismissedReviewRequestNumberOfLaunchesInterval
            : Constants.normalReviewRequestNumberOfLaunchesInterval
    }

    private lazy var calendar = Calendar(identifier: .gregorian)

    private let rateAppActionSubject = PassthroughSubject<RateAppAction, Never>()

    init() {
        trimStorageIfNeeded()
    }

    func registerBalances(of walletModels: [WalletModel]) {
        guard
            positiveBalanceAppearanceDate == nil,
            walletModels.contains(where: { !$0.wallet.isEmpty }) // Check if at least one wallet has a non-empty (non-zero) balance
        else {
            return
        }

        positiveBalanceAppearanceDate = Date()
    }

    func requestRateAppIfAvailable(with request: RateAppRequest) {
        if request.isLocked {
            return
        }

        guard request.isBalanceLoaded else {
            return
        }

        if positiveBalanceAppearanceDate == nil {
            return
        }

        guard abs(lastRequestedReviewDate.timeIntervalSinceNow) >= Constants.reviewRequestTimeInterval else {
            return
        }

        guard currentLaunchCount - lastRequestedReviewLaunchCount >= requiredNumberOfLaunches else {
            return
        }

        if request.displayedNotifications.contains(where: { Constants.forbiddenSeverityLevels.contains($0.severity) }) {
            return
        }

        guard let referenceDate = calendar.date(byAdding: .year, value: -Constants.systemReviewPromptTimeWindowSize, to: Date()) else {
            return
        }

        let systemReviewPromptRequestDatesWithinLastYear = systemReviewPromptRequestDates.filter { $0 >= referenceDate }

        guard systemReviewPromptRequestDatesWithinLastYear.count < Constants.systemReviewPromptMaxCountPerYear else {
            return
        }

        requestRateApp()
    }

    func respondToRateAppDialog(with response: RateAppResponse) {
        sendAnalyticsEvent(for: response)

        switch response {
        case .positive:
            systemReviewPromptRequestDates.append(Date())
            rateAppActionSubject.send(.openAppStoreReview)
        case .negative:
            rateAppActionSubject.send(.openFeedbackMailWithEmailType(emailType: .negativeRateAppFeedback))
        case .dismissed:
            userDismissedLastRequestedReview = true
        }
    }

    private func sendAnalyticsEvent(for response: RateAppResponse) {
        let parameterValue: Analytics.ParameterValue

        switch response {
        case .positive:
            parameterValue = .appStoreReview
        case .negative:
            parameterValue = .feedbackEmail
        case .dismissed:
            parameterValue = .appRateSheetDismissed
        }

        Analytics.log(.mainNoticeRateTheApp, params: [.result: parameterValue])
    }

    private func requestRateApp() {
        lastRequestedReviewDate = Date()
        lastRequestedReviewLaunchCount = currentLaunchCount
        userDismissedLastRequestedReview = false
        rateAppActionSubject.send(.openAppRateDialog)
    }

    private func trimStorageIfNeeded() {
        let storageMaxSize = Constants.systemReviewPromptRequestDatesMaxSize
        if systemReviewPromptRequestDates.count > storageMaxSize {
            systemReviewPromptRequestDates = systemReviewPromptRequestDates.suffix(storageMaxSize)
        }
    }
}

// MARK: - Auxiliary types

private extension RateAppService {
    enum StorageKeys: String, RawRepresentable {
        case systemReviewPromptRequestDates = "system_review_prompt_request_dates"
        case lastRequestedReviewDate = "last_requested_review_date"
        case lastRequestedReviewLaunchCount = "last_requested_review_launch_count"
        case userDismissedLastRequestedReview = "user_dismissed_last_requested_review"
    }
}

// MARK: - Constants

private extension RateAppService {
    enum Constants {
        // MARK: - Constants that control the behavior of the rate app sheet itself

        /// The user interacted with the review prompt.
        static let normalReviewRequestNumberOfLaunchesInterval = 3
        /// The user dismissed the review prompt w/o interaction.
        static let dismissedReviewRequestNumberOfLaunchesInterval = 20
        /// Three days.
        static let reviewRequestTimeInterval: TimeInterval = 3600 * 24 * 3

        static let forbiddenSeverityLevels: Set<NotificationView.Severity> = [
            .warning,
            .critical,
        ]

        // MARK: - Constants that control the behavior of the system rate app prompt (`SKStoreReviewController`)

        /// See https://developer.apple.com/documentation/storekit/requesting_app_store_reviews for details.
        static let systemReviewPromptMaxCountPerYear = 3
        /// Years, see https://developer.apple.com/documentation/storekit/requesting_app_store_reviews for details.
        static let systemReviewPromptTimeWindowSize = 1
        /// For storage trimming.
        static let systemReviewPromptRequestDatesMaxSize = 5
    }
}
