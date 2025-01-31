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
    func saveRefreshTokenToStorage(refreshToken: String, cardId: String) throws
}

protocol AuthorizationTokenHandler {
    var accessToken: JWT? { get async }
    var containsAccessToken: Bool { get async }
    var authorizationHeader: String { get async throws }
    var authorizationTokens: VisaAuthorizationTokens? { get async }
    func setupTokens(_ tokens: VisaAuthorizationTokens) async throws
    func forceRefreshToken() async throws
    func setupRefreshTokenSaver(_ refreshTokenSaver: VisaRefreshTokenSaver)
}

class CommonVisaAccessTokenHandler {
    private let tokenRefreshService: VisaAuthorizationTokenRefreshService
    private weak var refreshTokenSaver: VisaRefreshTokenSaver?

    private let cardId: String
    private let scheduler: AsyncTaskScheduler = .init()
    private let logger: InternalLogger

    private let accessTokenHolder: AccessTokenHolder
    private var refresherTask: AnyCancellable?

    private let minSecondsBeforeExpiration: TimeInterval = 60.0

    init(
        cardId: String,
        accessTokenHolder: AccessTokenHolder,
        tokenRefreshService: VisaAuthorizationTokenRefreshService,
        logger: InternalLogger,
        refreshTokenSaver: VisaRefreshTokenSaver?
    ) {
        self.cardId = cardId
        self.accessTokenHolder = accessTokenHolder
        self.tokenRefreshService = tokenRefreshService
        self.refreshTokenSaver = refreshTokenSaver
        self.logger = logger

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
                guard await self?.accessTokenHolder.authorizationTokens != nil else {
                    return
                }

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
        guard let jwtTokens = await accessTokenHolder.tokens else {
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
            guard let jwtTokens = await self?.accessTokenHolder.tokens else {
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

    @discardableResult
    private func refreshAccessToken(refreshJWTToken: JWT) async throws -> DecodedAuthorizationJWTTokens {
        log("Refreshing access token")
        if refreshJWTToken.expired {
            log("Refresh token expired, cant refresh")
            throw VisaAccessTokenHandlerError.refreshTokenExpired
        }

        let visaTokens = try await tokenRefreshService.refreshAccessToken(refreshToken: refreshJWTToken.string)
        let newJWTTokens = try AuthorizationTokensUtility().decodeAuthTokens(visaTokens)

        if newJWTTokens.accessToken.expired {
            throw VisaAccessTokenHandlerError.failedToUpdateAccessToken
        }

        await accessTokenHolder.setTokens(newJWTTokens)
        try refreshTokenSaver?.saveRefreshTokenToStorage(refreshToken: newJWTTokens.refreshToken.string, cardId: cardId)
        return newJWTTokens
    }
}

extension CommonVisaAccessTokenHandler: AuthorizationTokenHandler {
    var accessToken: JWT? {
        get async { await accessTokenHolder.tokens?.accessToken }
    }

    var containsAccessToken: Bool {
        get async { await accessTokenHolder.tokens != nil }
    }

    var authorizationHeader: String {
        get async throws {
            guard let jwtTokens = await accessTokenHolder.tokens else {
                throw VisaAccessTokenHandlerError.missingAccessToken
            }

            return AuthorizationTokensUtility().getAuthorizationHeader(from: jwtTokens)
        }
    }

    var authorizationTokens: VisaAuthorizationTokens? {
        get async {
            await accessTokenHolder.authorizationTokens
        }
    }

    func setupTokens(_ tokens: VisaAuthorizationTokens) async throws {
        log("Setup new authorization tokens in token handler")
        try await accessTokenHolder.setTokens(authorizationTokens: tokens)
        /// We need to use `setupRefresherTask` to prevent blocking current task
        setupRefresherTask()
    }

    func forceRefreshToken() async throws {
        guard let tokens = await accessTokenHolder.tokens else {
            log("Nothing to refresh")
            return
        }

        let newTokens = try await refreshAccessToken(refreshJWTToken: tokens.refreshToken)
        try refreshTokenSaver?.saveRefreshTokenToStorage(refreshToken: newTokens.refreshToken.string, cardId: cardId)
    }

    func setupRefreshTokenSaver(_ refreshTokenSaver: any VisaRefreshTokenSaver) {
        self.refreshTokenSaver = refreshTokenSaver
        runTask(in: self) { handler in
            do {
                guard let tokens = await handler.accessTokenHolder.tokens else {
                    handler.log("Nothing to save")
                    return
                }

                try refreshTokenSaver.saveRefreshTokenToStorage(
                    refreshToken: tokens.refreshToken.string,
                    cardId: handler.cardId
                )
            } catch {
                handler.log("Failed to save refresh token after saver setup. Error: \(error)")
            }
        }
    }
}
