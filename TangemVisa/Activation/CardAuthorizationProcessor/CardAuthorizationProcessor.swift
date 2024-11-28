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
    // Task implementation
    func getAuthorizationChallenge(for input: VisaCardActivationInput) async throws -> String
    func getAccessToken(
        signedChallenge: Data,
        salt: Data,
        cardInput: VisaCardActivationInput
    ) async throws -> VisaAuthorizationTokens

    // Async implementation
    func authorizeCard(with input: VisaCardActivationInput) async throws -> CardAuthorizationResult
}

final class CommonCardAuthorizationProcessor {
    private var authorizationChallengeInput: (sessionId: String, cardInput: VisaCardActivationInput)?

    private let tangemSdk: TangemSdk
    private let authorizationService: VisaAuthorizationService
    private let logger: InternalLogger

    init(
        tangemSdk: TangemSdk,
        authorizationService: VisaAuthorizationService,
        logger: InternalLogger
    ) {
        self.tangemSdk = tangemSdk
        self.authorizationService = authorizationService
        self.logger = logger
    }

    private func log<T>(_ message: @autoclosure () -> T) {
        logger.debug(subsystem: .cardAuthorizationProcessor, message())
    }
}

extension CommonCardAuthorizationProcessor {
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

extension CommonCardAuthorizationProcessor: CardAuthorizationProcessor {
    func authorizeCard(with input: VisaCardActivationInput) async throws -> CardAuthorizationResult {
        let challenge = try await getAuthorizationChallenge(for: input)

        log("Attempting to start NFC session")
        let cardSession: CardSession = try await withCheckedThrowingContinuation { continuation in
            tangemSdk.startSession(cardId: input.cardId) { [weak self] session, error in
                if let error {
                    self?.log("Failed to start session. Reason: \(error)")
                    if error.isUserCancelled {
                        session.stop()
                    } else {
                        session.stop(error: error, completion: nil)
                    }
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: session)
                }
            }
        }

        let challengeData = Data(hexString: challenge)
        let signChallengeCommand = AttestCardKeyCommand(challenge: challengeData)
        log("Attempting to sign challenge using ")
        let signResult = try await signChallengeCommand.run(in: cardSession)

        let accessToken: VisaAuthorizationTokens
        do {
            accessToken = try await getAccessToken(
                signedChallenge: signResult.cardSignature,
                salt: signResult.salt,
                cardInput: input
            )
        } catch {
            throw CardAuthorizationProcessorError.networkError(error)
        }

        return .init(authorizationTokens: accessToken, cardSession: cardSession)
    }
}
