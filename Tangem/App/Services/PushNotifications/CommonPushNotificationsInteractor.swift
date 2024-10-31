//
//  CommonPushNotificationsInteractor.swift
//  Tangem
//
//  Created by Andrey Fedorov on 26.06.2024.
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

    @AppStorageCompat(StorageKeys.didPostponeAuthorizationRequestOnWalletOnboarding)
    private var didPostponeAuthorizationRequestOnWalletOnboarding = false

    @AppStorageCompat(StorageKeys.didPostponeAuthorizationRequestOnWelcomeOnboarding)
    private var didPostponeAuthorizationRequestOnWelcomeOnboarding = false

    private var didPostponeAuthorizationRequestOnWelcomeOnboardingInCurrentSession = false

    private var currentLaunchCount: Int { AppSettings.shared.numberOfLaunches }

    private let pushNotificationsService: PushNotificationsService

    init(
        pushNotificationsService: PushNotificationsService
    ) {
        self.pushNotificationsService = pushNotificationsService
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

    private func logAllowRequest(in flow: PushNotificationsPermissionRequestFlow) {
        let source = analyticsSourceValue(for: flow)
        Analytics.log(.pushButtonAllow, params: [.source: source])
    }

    private func logPostponedRequest(in flow: PushNotificationsPermissionRequestFlow) {
        let source = analyticsSourceValue(for: flow)
        Analytics.log(.pushButtonPostpone, params: [.source: source])
    }

    private func logAuthorizationStatus() async {
        let state: Analytics.ParameterValue = await pushNotificationsService.isAuthorized ? .allow : .cancel
        Analytics.log(.pushPermissionStatus, params: [.state: state])
    }

    private func analyticsSourceValue(for flow: PushNotificationsPermissionRequestFlow) -> Analytics.ParameterValue {
        switch flow {
        case .welcomeOnboarding:
            return .stories
        case .walletOnboarding:
            return .onboarding
        case .afterLogin:
            return .main
        }
    }
}

// MARK: - PushNotificationsInteractor protocol conformance

extension CommonPushNotificationsInteractor: PushNotificationsInteractor {
    func isAvailable(in flow: PushNotificationsPermissionRequestFlow) -> Bool {
        guard
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
            return hasSavedWalletsFromPreviousVersion ?? false
        }
    }

    func allowRequest(in flow: PushNotificationsPermissionRequestFlow) async {
        logAllowRequest(in: flow)
        await pushNotificationsService.requestAuthorizationAndRegister()
        await logAuthorizationStatus()
        runOnMain {
            canRequestAuthorization = false
        }
    }

    func postponeRequest(in flow: PushNotificationsPermissionRequestFlow) {
        switch flow {
        case .welcomeOnboarding:
            didPostponeAuthorizationRequestOnWelcomeOnboarding = true
            didPostponeAuthorizationRequestOnWelcomeOnboardingInCurrentSession = true
        case .walletOnboarding:
            didPostponeAuthorizationRequestOnWalletOnboarding = true
        case .afterLogin:
            // Stop all future authorization requests
            canRequestAuthorization = false
        }

        logPostponedRequest(in: flow)
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
    }
}
