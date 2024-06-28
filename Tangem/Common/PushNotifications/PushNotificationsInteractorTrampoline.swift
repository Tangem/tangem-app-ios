//
//  PushNotificationsInteractorTrampoline.swift
//  Tangem
//
//  Created by m3g0byt3 on 26.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class PushNotificationsInteractorTrampoline {
    typealias IsAvailable = () -> Bool
    typealias CanPostponePermissionRequest = IsAvailable
    typealias AllowRequest = () async -> Void
    typealias PostponeRequest = () -> Void

    private let _isAvailable: IsAvailable
    private let _canPostponePermissionRequest: CanPostponePermissionRequest
    private let _allowRequest: AllowRequest
    private let _postponeRequest: PostponeRequest

    internal init(
        isAvailable: @escaping IsAvailable,
        canPostponePermissionRequest: @escaping CanPostponePermissionRequest,
        allowRequest: @escaping AllowRequest,
        postponeRequest: @escaping PostponeRequest
    ) {
        _isAvailable = isAvailable
        _canPostponePermissionRequest = canPostponePermissionRequest
        _allowRequest = allowRequest
        _postponeRequest = postponeRequest
    }
}

// MARK: - PushNotificationsAvailabilityProvider protocol conformance

extension PushNotificationsInteractorTrampoline: PushNotificationsAvailabilityProvider {
    var isAvailable: Bool {
        _isAvailable()
    }
}

// MARK: - PushNotificationsPermissionManager protocol conformance

extension PushNotificationsInteractorTrampoline: PushNotificationsPermissionManager {
    var canPostponePermissionRequest: Bool {
        _canPostponePermissionRequest()
    }

    func allowPermissionRequest() async {
        await _allowRequest()
    }

    func postponePermissionRequest() {
        _postponeRequest()
    }
}
