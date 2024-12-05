//
//  VisaActivationManager.swift
//  TangemVisa
//
//  Created by Andrew Son on 01.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemSdk

public protocol VisaActivationManager: VisaAccessCodeValidator {
    func saveAccessCode(accessCode: String) throws
    func resetAccessCode()
    func setupRefreshTokenSaver(_ refreshTokenSaver: VisaRefreshTokenSaver)

    func startActivation() async throws
}

public protocol VisaAccessCodeValidator: AnyObject {
    func validateAccessCode(accessCode: String) throws
}

final class CommonVisaActivationManager {
    private var selectedAccessCode: String?

    private let authorizationService: VisaAuthorizationService
    private let authorizationTokenHandler: AuthorizationTokenHandler
    private let tangemSdk: TangemSdk

    private let authorizationProcessor: CardAuthorizationProcessor
    private let cardSetupHandler: CardSetupHandler
    private let cardActivationOrderProvider: CardActivationOrderProvider

    private let logger: InternalLogger

    private let cardInput: VisaCardActivationInput
    private var activationTask: AnyCancellable?

    init(
        cardInput: VisaCardActivationInput,
        authorizationService: VisaAuthorizationService,
        authorizationTokenHandler: AuthorizationTokenHandler,
        tangemSdk: TangemSdk,
        authorizationProcessor: CardAuthorizationProcessor,
        cardSetupHandler: CardSetupHandler,
        cardActivationOrderProvider: CardActivationOrderProvider,
        logger: InternalLogger
    ) {
        self.cardInput = cardInput

        self.authorizationService = authorizationService
        self.authorizationTokenHandler = authorizationTokenHandler
        self.tangemSdk = tangemSdk

        self.authorizationProcessor = authorizationProcessor
        self.cardSetupHandler = cardSetupHandler
        self.cardActivationOrderProvider = cardActivationOrderProvider

        self.logger = logger
    }

    private func log<T>(_ message: @autoclosure () -> T) {
        logger.debug(subsystem: .activationManager, message())
    }
}

extension CommonVisaActivationManager: VisaActivationManager {
    func validateAccessCode(accessCode: String) throws {
        guard accessCode.count >= 4 else {
            throw VisaAccessCodeValidationError.accessCodeIsTooShort
        }
    }

    func saveAccessCode(accessCode: String) throws {
        try validateAccessCode(accessCode: accessCode)

        selectedAccessCode = accessCode
    }

    func resetAccessCode() {
        selectedAccessCode = nil
    }

    func setupRefreshTokenSaver(_ refreshTokenSaver: VisaRefreshTokenSaver) {
        authorizationTokenHandler.setupRefreshTokenSaver(refreshTokenSaver)
    }

    func startActivation() async throws {
        guard activationTask == nil else {
            log("Activation task already exists, skipping")
            return
        }

        guard let selectedAccessCode else {
            throw VisaActivationError.missingAccessCode
        }

        try await taskActivation(accessCode: selectedAccessCode)
    }
}

// MARK: - Task implementation

extension CommonVisaActivationManager: SignedAuthorizationChallengeDelegate {
    func challengeSigned(signedChallenge: Data, salt: Data, completion: @escaping (Result<Void, Error>) -> Void) {
        Task { [weak self] in
            guard let self else {
                return
            }

            do {
                let tokens = try await authorizationProcessor.getAccessToken(
                    signedChallenge: signedChallenge,
                    salt: salt,
                    cardInput: cardInput
                )
                try await authorizationTokenHandler.setupTokens(tokens)
                completion(.success(()))
            } catch {
                log("Failed to load authorization tokens: \(error)")
                completion(.failure(error))
            }
        }
    }

    func taskActivation(accessCode: String) async throws {
        do {
            var authorizationChallenge: String?
            if await authorizationTokenHandler.containsAccessToken {
                authorizationChallenge = try await authorizationProcessor.getAuthorizationChallenge(for: cardInput)
            }

            let activationResponse: VisaCardActivationResponse = try await withCheckedThrowingContinuation { [weak self] continuation in
                guard let self else {
                    continuation.resume(throwing: "Deinitialized")
                    return
                }

                let task = CardActivationTask(
                    selectedAccessCode: accessCode,
                    activationInput: cardInput,
                    challengeToSign: authorizationChallenge,
                    orderToSign: nil,
                    activationOrderProvider: cardActivationOrderProvider,
                    signedAuthorizationChallengeDelegate: self,
                    logger: logger
                )

                tangemSdk.startSession(with: task) { result in
                    switch result {
                    case .success(let response):
                        continuation.resume(with: .success(response))
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }

            log("Do something with activation response: \(activationResponse)")
        } catch let sdkError as TangemSdkError {
            if sdkError.isUserCancelled {
                return
            }

            log("Failed to activate card. Tangem SDK Error: \(sdkError)")
            throw VisaActivationError.underlyingError(sdkError)
        } catch {
            log("Failed to activate card. Generic error: \(error)")
            throw VisaActivationError.underlyingError(error)
        }
    }
}

// MARK: - Async Implementation

private extension CommonVisaActivationManager {
    func asyncActivation(accessCode: String) async throws {
        var cardSession: CardSession?

        do {
            cardSession = try await startCardSession()
            guard let cardSession else {
                log("Failed to find active NFC session")
                throw VisaActivationError.missingActiveCardSession
            }

            log("Continuing card setup with access code")
            try await cardSetupHandler.setupCard(accessCode: accessCode, in: cardSession)
            log("Start loading order info")
            let orderToSign = try await cardActivationOrderProvider.provideActivationOrderForSign()
            log("Receive order to sign")

            cardSession.stop(message: "Implemented activation flow finished successfully")
        } catch let tangemSdkError as TangemSdkError {
            if tangemSdkError.isUserCancelled {
                log("User cancelled operation")
                return
            }

            throw tangemSdkError
        } catch let error as CardAuthorizationProcessorError {
            log("Card authorization processor error: \(error)")
            cardSession?.stop(error: error, completion: nil)
            throw error
        } catch {
            log("Failed to finish activation. Reason: \(error)")
            log("Stopping NFC session")
            cardSession?.stop()
            log("Canceling card setup")
            cardSetupHandler.cancelCardSetup()
            log("Canceling loading of card activation order")
            cardActivationOrderProvider.cancelOrderLoading()
            log("Failed to activate Visa card")
            throw VisaActivationError.underlyingError(error)
        }
    }

    func startCardSession() async throws -> CardSession {
        if await authorizationTokenHandler.containsAccessToken {
            log( "Access token exists, flow not implemented")
            throw VisaActivationError.notImplemented
        } else {
            log("Authorization tokens not found, starting authorization process")
            let cardAuthorizationResult = try await authorizationProcessor.authorizeCard(with: cardInput)
            log("Authorization process successfully finished. Received access tokens and session")
            try await authorizationTokenHandler.setupTokens(cardAuthorizationResult.authorizationTokens)
            return cardAuthorizationResult.cardSession
        }
    }
}
