//
//  AuthorizationProcessor.swift
//  TangemVisa
//
//  Created by Andrew Son on 25.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct CardAuthorizationResult {
    let authorizationTokens: VisaAuthorizationTokens
    let cardSession: CardSession
}

protocol CardAuthorizationProcessor {
    func getAuthorizationChallenge(for input: VisaCardActivationInput) async throws -> String
    func getAccessToken(
        signedChallenge: Data,
        salt: Data,
        cardInput: VisaCardActivationInput
    ) async throws -> VisaAuthorizationTokens
}

final class CommonCardAuthorizationProcessor {
    private var authorizationChallengeInput: (sessionId: String, cardInput: VisaCardActivationInput)?

    private let authorizationService: VisaAuthorizationService
    private let logger: InternalLogger

    init(
        authorizationService: VisaAuthorizationService,
        logger: InternalLogger
    ) {
        self.authorizationService = authorizationService
        self.logger = logger
    }

    private func log<T>(_ message: @autoclosure () -> T) {
        logger.debug(subsystem: .cardAuthorizationProcessor, message())
    }
}

extension CommonCardAuthorizationProcessor: CardAuthorizationProcessor {
    func getAuthorizationChallenge(for input: VisaCardActivationInput) async throws -> String {
        log("Attempting to load authorization challenge")
        let challengeResponse = try await authorizationService.getAuthorizationChallenge(
            cardId: input.cardId,
            cardPublicKey: input.cardPublicKey.hexString
        )

        log("Challenge loaded, saving session id")
        authorizationChallengeInput = (sessionId: challengeResponse.sessionId, cardInput: input)
        return challengeResponse.nonce
    }

    func getAccessToken(
        signedChallenge: Data,
        salt: Data,
        cardInput: VisaCardActivationInput
    ) async throws -> VisaAuthorizationTokens {
        guard let authorizationChallengeInput else {
            log("Failed to find saved authorization challenge input and session")
            throw CardAuthorizationProcessorError.authorizationChallengeNotFound
        }

        guard authorizationChallengeInput.cardInput == cardInput else {
            log("Card input in authorization challenge input didn't match with input provided")
            throw CardAuthorizationProcessorError.invalidCardInput
        }

        log("Attempting to load access tokens for signed challenge")
        do {
            let accessTokens = try await authorizationService.getAccessTokens(
                signedChallenge: signedChallenge.hexString,
                salt: salt.hexString,
                sessionId: authorizationChallengeInput.sessionId
            )
            return accessTokens
        } catch {
            throw CardAuthorizationProcessorError.networkError(error)
        }
    }
}
