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

    @AppStorageCompat(StorageKeys.didAttemptMigrationFromLegacyRateApp)
    private var didAttemptMigrationFromLegacyRateApp: Bool = false

    @AppStorageCompat(StorageKeys.positiveBalanceAppearanceDate)
    private var positiveBalanceAppearanceDate: Date? = nil

    @AppStorageCompat(StorageKeys.positiveBalanceAppearanceLaunchCount)
    private var positiveBalanceAppearanceLaunchCount: Int? = nil

    @AppStorageCompat(StorageKeys.userRespondedToLastRequestedReview)
    private var userRespondedToLastRequestedReview: Bool = false

    @AppStorageCompat(StorageKeys.userDismissedLastRequestedReviewDate)
    private var userDismissedLastRequestedReviewDate: Date? = nil

    @AppStorageCompat(StorageKeys.userDismissedLastRequestedReviewLaunchCount)
    private var userDismissedLastRequestedReviewLaunchCount: Int? = nil

    private var userDismissedLastRequestedReview: Bool {
        return userDismissedLastRequestedReviewDate != nil && userDismissedLastRequestedReviewLaunchCount != nil
    }

    private var currentLaunchCount: Int { AppSettings.shared.numberOfLaunches }

    private var requiredNumberOfLaunches: Int {
        return userDismissedLastRequestedReview
            ? Constants.dismissedReviewRequestNumberOfLaunchesInterval
            : Constants.normalReviewRequestNumberOfLaunchesInterval
    }

    private let rateAppActionSubject = PassthroughSubject<RateAppAction, Never>()

    init() {
        migrateFromLegacyRateAppIfNeeded()
    }

    func registerBalances(of walletModels: [WalletModel]) {
        guard
            positiveBalanceAppearanceDate == nil,
            walletModels.contains(where: { !$0.wallet.isEmpty }) // Check if at least one wallet has a non-empty (non-zero) balance
        else {
            return
        }

        positiveBalanceAppearanceDate = Date()
        positiveBalanceAppearanceLaunchCount = currentLaunchCount
    }

    func requestRateAppIfAvailable(with request: RateAppRequest) {
        if userRespondedToLastRequestedReview {
            return
        }

        if request.isLocked {
            return
        }

        guard request.isBalanceLoaded else {
            return
        }

        if positiveBalanceAppearanceDate == nil {
            return
        }

        guard
            let date = (userDismissedLastRequestedReviewDate ?? positiveBalanceAppearanceDate),
            abs(date.timeIntervalSinceNow) >= Constants.reviewRequestTimeInterval
        else {
            return
        }

        guard
            let launchCount = (userDismissedLastRequestedReviewLaunchCount ?? positiveBalanceAppearanceLaunchCount),
            currentLaunchCount - launchCount >= requiredNumberOfLaunches
        else {
            return
        }

        if request.displayedNotifications.contains(where: { Constants.forbiddenSeverityLevels.contains($0.severity) }) {
            return
        }

        requestRateApp()
    }

    func respondToRateAppDialog(with response: RateAppResponse) {
        sendAnalyticsEvent(for: response)

        switch response {
        case .positive:
            userRespondedToLastRequestedReview = true
            rateAppActionSubject.send(.openAppStoreReview)
        case .negative:
            userRespondedToLastRequestedReview = true
            rateAppActionSubject.send(.openFeedbackMailWithEmailType(emailType: .negativeRateAppFeedback))
        case .dismissed:
            userDismissedLastRequestedReviewDate = Date()
            userDismissedLastRequestedReviewLaunchCount = currentLaunchCount
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
        userDismissedLastRequestedReviewDate = nil
        userDismissedLastRequestedReviewLaunchCount = nil
        rateAppActionSubject.send(.openAppRateDialog)
    }

    private func migrateFromLegacyRateAppIfNeeded() {
        if didAttemptMigrationFromLegacyRateApp {
            return
        }

        didAttemptMigrationFromLegacyRateApp = true

        // A fresh install without using the old version with legacy `RateAppService`
        if currentLaunchCount <= 1 {
            return
        }

        // An upgrade from the previous version with legacy `RateAppService`, therefore we have to
        // postpone the upcoming rate app request even if all conditions for it are met

        if positiveBalanceAppearanceDate != nil {
            positiveBalanceAppearanceDate = Date()
        }

        if positiveBalanceAppearanceLaunchCount != nil {
            positiveBalanceAppearanceLaunchCount = currentLaunchCount
        }
    }
}

// MARK: - Auxiliary types

private extension RateAppService {
    enum StorageKeys: String, RawRepresentable {
        case positiveBalanceAppearanceDate = "tangem_tap_positive_balace_appearance_date"
        case positiveBalanceAppearanceLaunchCount = "tangem_tap_positive_balance_appearance_launch"
        case userDismissedLastRequestedReviewDate = "user_dismissed_last_requested_review_date"
        case userDismissedLastRequestedReviewLaunchCount = "user_dismissed_last_requested_review_launch_count"
        case userRespondedToLastRequestedReview = "user_responded_to_last_requested_review"
        case didAttemptMigrationFromLegacyRateApp = "did_attempt_migration_from_legacy_rate_app"
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
    }
}
