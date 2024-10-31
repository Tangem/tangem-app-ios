//
//  PushNotificationsHelpersFactory.swift
//  Tangem
//
//  Created by Andrey Fedorov on 27.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct PushNotificationsHelpersFactory {
    func makeAvailabilityProviderForWelcomeOnboarding(
        using interactor: PushNotificationsInteractor
    ) -> PushNotificationsAvailabilityProvider {
        return makeTrampolineForFlow(.welcomeOnboarding, using: interactor)
    }

    func makeAvailabilityProviderForWalletOnboarding(
        using interactor: PushNotificationsInteractor
    ) -> PushNotificationsAvailabilityProvider {
        return makeTrampolineForFlow(.walletOnboarding, using: interactor)
    }

    func makeAvailabilityProviderForAfterLogin(
        using interactor: PushNotificationsInteractor
    ) -> PushNotificationsAvailabilityProvider {
        return makeTrampolineForFlow(.afterLogin, using: interactor)
    }

    func makePermissionManagerForWelcomeOnboarding(
        using interactor: PushNotificationsInteractor
    ) -> PushNotificationsPermissionManager {
        return makeTrampolineForFlow(.welcomeOnboarding, using: interactor)
    }

    func makePermissionManagerForWalletOnboarding(
        using interactor: PushNotificationsInteractor
    ) -> PushNotificationsPermissionManager {
        return makeTrampolineForFlow(.walletOnboarding, using: interactor)
    }

    func makePermissionManagerForAfterLogin(
        using interactor: PushNotificationsInteractor) -> PushNotificationsPermissionManager {
        return makeTrampolineForFlow(.afterLogin, using: interactor)
    }

    private func makeTrampolineForFlow(
        _ flow: PushNotificationsPermissionRequestFlow,
        using interactor: PushNotificationsInteractor
    ) -> InteractorTrampoline {
        return InteractorTrampoline(
            isAvailable: { interactor.isAvailable(in: flow) },
            allowRequest: { await interactor.allowRequest(in: flow) },
            postponeRequest: { interactor.postponeRequest(in: flow) }
        )
    }
}

// MARK: - Auxiliary types

private extension PushNotificationsHelpersFactory {
    /// Proxy that forwards all calls from `PushNotificationsAvailabilityProvider` and `PushNotificationsPermissionManager`
    /// interfaces to the opaque wrapped underlying entity using closures.
    final class InteractorTrampoline: PushNotificationsAvailabilityProvider, PushNotificationsPermissionManager {
        typealias IsAvailable = () -> Bool
        typealias AllowRequest = () async -> Void
        typealias PostponeRequest = () -> Void

        var isAvailable: Bool { _isAvailable() }

        private let _isAvailable: IsAvailable
        private let _allowRequest: AllowRequest
        private let _postponeRequest: PostponeRequest

        init(
            isAvailable: @escaping IsAvailable,
            allowRequest: @escaping AllowRequest,
            postponeRequest: @escaping PostponeRequest
        ) {
            _isAvailable = isAvailable
            _allowRequest = allowRequest
            _postponeRequest = postponeRequest
        }

        func allowPermissionRequest() async {
            await _allowRequest()
        }

        func postponePermissionRequest() {
            _postponeRequest()
        }
    }
}
