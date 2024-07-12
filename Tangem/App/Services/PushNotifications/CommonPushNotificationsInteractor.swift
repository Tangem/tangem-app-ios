//
//  CommonPushNotificationsInteractor.swift
//  Tangem
//
//  Created by m3g0byt3 on 26.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class CommonPushNotificationsInteractor {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    /// Optional bool because this property is updated only once,
    /// on the very first launch of the app version with push notifications support.
    @AppStorageCompat(StorageKeys.hasSavedWalletsFromPreviousVersion)
    private var hasSavedWalletsFromPreviousVersion: Bool? = nil

    @AppStorageCompat(StorageKeys.canRequestAuthorization)
    private var canRequestAuthorization = true

    /// Note: - Updated only in `.newUser(state: .walletOnboarding)` and `.existingUser` flows.
    @AppStorageCompat(StorageKeys.postponedAuthorizationRequestLaunchCount)
    private var postponedAuthorizationRequestLaunchCount: Int? = nil

    /// Note: - Updated only in `.newUser(state: .walletOnboarding)` and `.existingUser` flows.
    @AppStorageCompat(StorageKeys.postponedAuthorizationRequestDate)
    private var postponedAuthorizationRequestDate: Date? = nil

    @AppStorageCompat(StorageKeys.numberOfRequestsPostponedByExistingUser)
    private var numberOfRequestsPostponedByExistingUser = 0

    @AppStorageCompat(StorageKeys.didPostponeAuthorizationRequestOnWalletOnboarding)
    private var didPostponeAuthorizationRequestOnWalletOnboarding = false

    @AppStorageCompat(StorageKeys.didPostponeAuthorizationRequestOnWelcomeOnboarding)
    private var didPostponeAuthorizationRequestOnWelcomeOnboarding = false

    private var didPostponeAuthorizationRequestOnWelcomeOnboardingInCurrentSession = false

    private var currentLaunchCount: Int { AppSettings.shared.numberOfLaunches }

    private var isFeatureFlagEnabled: Bool { FeatureProvider.isAvailable(.pushNotifications) }

    private let pushNotificationsService: PushNotificationsService

    init(
        pushNotificationsService: PushNotificationsService
    ) {
        self.pushNotificationsService = pushNotificationsService
    }

    private func saveLaunchCountAndDateOfPostponedRequest() {
        postponedAuthorizationRequestLaunchCount = currentLaunchCount
        postponedAuthorizationRequestDate = .now
    }

    private func updateSavedWalletsStatusIfNeeded() {
        // Runs only once per installation
        guard hasSavedWalletsFromPreviousVersion == nil else {
            return
        }

        hasSavedWalletsFromPreviousVersion = userWalletRepository.hasSavedWallets
    }

    private func registerIfPossible() {
        runTask(in: self) { interactor in
            await interactor.pushNotificationsService.registerIfPossible()
        }
    }
}

// MARK: - PushNotificationsInteractor protocol conformance

extension CommonPushNotificationsInteractor: PushNotificationsInteractor {
    func isAvailable(in flow: PushNotificationsPermissionRequestFlow) -> Bool {
        guard
            isFeatureFlagEnabled,
            canRequestAuthorization
        else {
            return false
        }

        switch flow {
        case .welcomeOnboarding:
            return !didPostponeAuthorizationRequestOnWelcomeOnboarding
        case .walletOnboarding:
            return !didPostponeAuthorizationRequestOnWelcomeOnboardingInCurrentSession
                && !didPostponeAuthorizationRequestOnWalletOnboarding
        case .afterLogin:
            guard
                let postponedAuthorizationRequestLaunchCount,
                let postponedAuthorizationRequestDate
            else {
                // `postponedAuthorizationRequestLaunchCount` and `postponedAuthorizationRequestDate` can be nil in some cases,
                // for example on the first call with `PermissionRequestFlow.afterLogin` if user has saved wallets
                return true
            }

            let launchCountSinceLastPostponedRequest = postponedAuthorizationRequestLaunchCount
                + Constants.finalAuthorizationRequestNumberOfLaunchesDiff

            let timeIntervalSinceLastPostponedRequest = abs(postponedAuthorizationRequestDate.timeIntervalSinceNow)

            return currentLaunchCount >= launchCountSinceLastPostponedRequest
                && timeIntervalSinceLastPostponedRequest >= Constants.finalAuthorizationRequestTimeIntervalDiff
        }
    }

    func allowRequest(in _: PushNotificationsPermissionRequestFlow) async {
        await pushNotificationsService.requestAuthorizationAndRegister()
        runOnMain {
            canRequestAuthorization = false
        }
    }

    func canPostponeRequest(in flow: PushNotificationsPermissionRequestFlow) -> Bool {
        switch flow {
        case .welcomeOnboarding, .walletOnboarding:
            return true
        case .afterLogin where hasSavedWalletsFromPreviousVersion == true:
            // In this case only the first `Constants.maxNumberOfRequestsCanBePostponed`-th
            // permissions authorization requests can be postponed
            return numberOfRequestsPostponedByExistingUser < Constants.maxNumberOfRequestsCanBePostponed
        case .afterLogin:
            return false
        }
    }

    func postponeRequest(in flow: PushNotificationsPermissionRequestFlow) {
        switch flow {
        case .welcomeOnboarding:
            saveLaunchCountAndDateOfPostponedRequest()
            didPostponeAuthorizationRequestOnWelcomeOnboarding = true
            didPostponeAuthorizationRequestOnWelcomeOnboardingInCurrentSession = true
        case .walletOnboarding:
            saveLaunchCountAndDateOfPostponedRequest()
            didPostponeAuthorizationRequestOnWalletOnboarding = true
        case .afterLogin where hasSavedWalletsFromPreviousVersion == true:
            saveLaunchCountAndDateOfPostponedRequest()
            numberOfRequestsPostponedByExistingUser += 1
            // Stop all future authorization requests if the user postpones the request
            // for the `Constants.maxNumberOfPostponedRequests`-th times
            if numberOfRequestsPostponedByExistingUser >= Constants.maxNumberOfPostponedRequests {
                canRequestAuthorization = false
            }
        case .afterLogin:
            // Stop all future authorization requests
            canRequestAuthorization = false
        }
    }
}

// MARK: - Initializable protocol conformance

extension CommonPushNotificationsInteractor: Initializable {
    func initialize() {
        updateSavedWalletsStatusIfNeeded()
        registerIfPossible()
    }
}

// MARK: - Constants

private extension CommonPushNotificationsInteractor {
    enum StorageKeys: String, RawRepresentable {
        case hasSavedWalletsFromPreviousVersion = "has_saved_wallets_from_previous_version"
        case canRequestAuthorization = "can_request_authorization"
        case didPostponeAuthorizationRequestOnWelcomeOnboarding = "did_postpone_authorization_request_on_welcome_onboarding"
        case didPostponeAuthorizationRequestOnWalletOnboarding = "did_postpone_authorization_request_on_wallet_onboarding"
        case numberOfRequestsPostponedByExistingUser = "number_of_requests_postponed_by_existing_user"
        case postponedAuthorizationRequestLaunchCount = "postponed_authorization_request_launch_count"
        case postponedAuthorizationRequestDate = "postponed_authorization_request_date"
    }

    enum Constants {
        // Five active sessions.
        static let finalAuthorizationRequestNumberOfLaunchesDiff = 5
        /// Three days.
        static let finalAuthorizationRequestTimeIntervalDiff: TimeInterval = 3600 * 24 * 3
        /// Note: Only applicable if user has saved wallets.
        static let maxNumberOfRequestsCanBePostponed = 1
        /// Note: Only applicable if user has saved wallets.
        static let maxNumberOfPostponedRequests = 2
    }
}
