//
//  AuthorizationTokensHandler.swift
//  TangemVisa
//
//  Created by Andrew Son on 13.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import JWTDecode

public protocol VisaRefreshTokenSaver: AnyObject {
    func saveRefreshTokenToStorage(refreshToken: String) async throws
}

protocol AuthorizationTokenHandler {
    func setupTokens(_ tokens: VisaAuthorizationTokens) async throws
    func authorizationHeader() async throws -> String
    func setupRefreshTokenSaver(_ refreshTokenSaver: VisaRefreshTokenSaver)
}

class CommonVisaAccessTokenHandler {
    private let tokenRefreshService: AccessTokenRefreshService
    private weak var refreshTokenSaver: VisaRefreshTokenSaver?

    private let scheduler: AsyncTaskScheduler = .init()
    private let logger: InternalLogger

    private let accessTokenHolder: AccessTokenHolder = .init()
    private var refresherTask: AnyCancellable?

    private let minSecondsBeforeExpiration: TimeInterval = 60.0

    init(
        tokenRefreshService: AccessTokenRefreshService,
        logger: InternalLogger,
        refreshTokenSaver: VisaRefreshTokenSaver?
    ) {
        self.tokenRefreshService = tokenRefreshService
        self.refreshTokenSaver = refreshTokenSaver
        self.logger = logger
    }

    init(
        authorizationTokens: VisaAuthorizationTokens,
        tokenRefreshService: AccessTokenRefreshService,
        logger: InternalLogger,
        refreshTokenSaver: VisaRefreshTokenSaver?
    ) async throws {
        self.tokenRefreshService = tokenRefreshService
        self.refreshTokenSaver = refreshTokenSaver
        self.logger = logger
        try await accessTokenHolder.setTokens(authorizationTokens: authorizationTokens)

        setupRefresherTask()
    }

    private func log(_ message: @autoclosure () -> String) {
        logger.debug(subsystem: .authorizationTokenHandler, message())
    }

    private func setupRefresherTask() {
        log("Setup refresher task. Current refresher task is nil: \(refresherTask == nil)")
        refresherTask?.cancel()
        refresherTask = Task { [weak self] in
            do {
                try await self?.setupAccessTokenRefresher()
            } catch {
                if error is CancellationError {
                    self?.log("Refresher task was cancelled")
                    return
                }
                self?.log("Failed to update access token. Reason: \(error)")
            }
        }.eraseToAnyCancellable()
    }

    private func setupAccessTokenRefresher() async throws {
        log("Attempting to setup token refresher")
        guard let jwtTokens = await accessTokenHolder.getTokens() else {
            throw VisaAccessTokenHandlerError.authorizationTokensNotFound
        }

        log("JWT tokens found. Checking expiration date.")
        guard
            let expirationDate = jwtTokens.accessToken.expiresAt,
            let issuedAtDate = jwtTokens.accessToken.issuedAt
        else {
            throw VisaAccessTokenHandlerError.missingMandatoryInfoInAccessToken
        }

        let now = Date()
        let timeBeforeExpiration = expirationDate.timeIntervalSince(now)
        let shouldRefreshToken = timeBeforeExpiration < minSecondsBeforeExpiration || jwtTokens.accessToken.expired

        // We need to refresh token before setup token update with fixed interval
        if shouldRefreshToken {
            log("Access token needs to be refreshed.")
            // Token already expired or will expire very soon. Refreshing
            try await refreshAccessToken(refreshJWTToken: jwtTokens.refreshToken)
        } else {
            log("Access token is not expired. Waiting until it will expire.")
            let maxDateBeforeUpdate = Calendar.current.date(
                byAdding: .second,
                value: -Int(minSecondsBeforeExpiration),
                to: expirationDate
            ) ?? now
            let refreshDelay = maxDateBeforeUpdate.timeIntervalSince(now)
            log("Access token will expire in \(expirationDate.timeIntervalSince(Date()))")
            log("Access token will be refreshed in \(refreshDelay) seconds.")

            // Wait until token will need to refresh and update it one time
            try await Task.sleep(seconds: refreshDelay)
            try await refreshAccessToken(refreshJWTToken: jwtTokens.refreshToken)
        }

        try Task.checkCancellation()
        log("Scheduling token update")
        // Setup recurring token update with fixed interval
        let tokenLifeTime = expirationDate.timeIntervalSince(issuedAtDate)
        let tokenRefreshTimeInterval = tokenLifeTime - minSecondsBeforeExpiration
        log("Scheduling token refresh job with interval: \(tokenRefreshTimeInterval)")
        scheduler.scheduleJob(interval: tokenRefreshTimeInterval, repeats: true) { [weak self] in
            self?.log("Access token is about to expire. Refreshing...")
            guard let jwtTokens = await self?.accessTokenHolder.getTokens() else {
                self?.log("Failed to find access token. Canceling scheduled job.")
                self?.scheduler.cancel()
                return
            }

            self?.log("Scheduled token update")
            do {
                try await self?.refreshAccessToken(refreshJWTToken: jwtTokens.refreshToken)
            } catch {
                self?.log("Failed to refresh access token. Reason: \(error)")
            }
        }
    }

    private func refreshAccessToken(refreshJWTToken: JWT) async throws {
        log("Refreshing access token")
        if refreshJWTToken.expired {
            log("Refresh token expired, cant refresh")
            throw VisaAccessTokenHandlerError.refreshTokenExpired
        }

        let visaTokens = try await tokenRefreshService.refreshAccessToken(refreshToken: refreshJWTToken.string)
        let newJWTTokens = try AuthorizationTokensDecoderUtility().decodeAuthTokens(visaTokens)

        if newJWTTokens.accessToken.expired {
            throw VisaAccessTokenHandlerError.failedToUpdateAccessToken
        }

        await accessTokenHolder.setTokens(newJWTTokens)
        try await refreshTokenSaver?.saveRefreshTokenToStorage(refreshToken: newJWTTokens.refreshToken.string)
    }
}

extension CommonVisaAccessTokenHandler: AuthorizationTokenHandler {
    func setupTokens(_ tokens: VisaAuthorizationTokens) async throws {
        log("Setup new authorization tokens in token handler")
        try await accessTokenHolder.setTokens(authorizationTokens: tokens)
        /// We need to use `setupRefresherTask` to prevent blocking current task
        setupRefresherTask()
    }

    func authorizationHeader() async throws -> String {
        guard let jwtTokens = await accessTokenHolder.getTokens() else {
            throw VisaAccessTokenHandlerError.missingAccessToken
        }

        return "Bearer \(jwtTokens.accessToken.string)"
    }

    func setupRefreshTokenSaver(_ refreshTokenSaver: any VisaRefreshTokenSaver) {
        self.refreshTokenSaver = refreshTokenSaver
    }
}
