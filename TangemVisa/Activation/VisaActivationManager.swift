//
//  VisaActivationManager.swift
//  TangemVisa
//
//  Created by Andrew Son on 01.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol VisaActivationManager {
    func saveAccessCode(_ accessCode: String) throws
    func resetAccessCode()
    func setupRefreshTokenSaver(_ refreshTokenSaver: VisaRefreshTokenSaver)

    // Will be updated in IOS-8509. Requirements for activation flow was reworked, so for now this function is for testing purposes
    func startActivation(_ tokens: VisaAuthorizationTokens) async throws
}

class CommonVisaActivationManager {
    private var selectedAccessCode: String?
    private let authorizationTokenHandler: AuthorizationTokenHandler

    init(authorizationTokenHandler: AuthorizationTokenHandler) {
        self.authorizationTokenHandler = authorizationTokenHandler
    }
}

extension CommonVisaActivationManager: VisaActivationManager {
    func saveAccessCode(_ accessCode: String) throws {
        guard accessCode.count >= 4 else {
            throw VisaActivationError.accessCodeIsTooShort
        }

        selectedAccessCode = accessCode
    }

    func resetAccessCode() {
        selectedAccessCode = nil
    }

    func setupRefreshTokenSaver(_ refreshTokenSaver: VisaRefreshTokenSaver) {
        authorizationTokenHandler.setupRefreshTokenSaver(refreshTokenSaver)
    }

    func startActivation(_ tokens: VisaAuthorizationTokens) async throws {
        try await authorizationTokenHandler.setupTokens(tokens)
    }
}

public struct VisaActivationManagerFactory {
    public init() {}

    public func make(urlSessionConfiguration: URLSessionConfiguration, logger: VisaLogger) -> VisaActivationManager {
        let internalLogger = InternalLogger(logger: logger)
        let tokenRefreshService = AuthorizationServiceBuilder().build(urlSessionConfiguration: urlSessionConfiguration, logger: logger)
        let tokenHandler = CommonVisaAccessTokenHandler(
            tokenRefreshService: tokenRefreshService,
            logger: internalLogger,
            refreshTokenSaver: nil
        )
        return CommonVisaActivationManager(authorizationTokenHandler: tokenHandler)
    }
}

public enum VisaActivationError: String, Error {
    case accessCodeIsTooShort
}
