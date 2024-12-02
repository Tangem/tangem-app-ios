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
        authorizationProcessor: CardAuthorizationProcessor,
        cardSetupHandler: CardSetupHandler,
        cardActivationOrderProvider: CardActivationOrderProvider,
        logger: InternalLogger
    ) {
        self.cardInput = cardInput

        self.authorizationService = authorizationService
        self.authorizationTokenHandler = authorizationTokenHandler

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

        var cardSession: CardSession?

        do {
            cardSession = try await startCardSession()
            guard let cardSession else {
                log("Failed to find active NFC session")
                throw VisaActivationError.missingActiveCardSession
            }

            log("Continuing card setup with access code")
            try await cardSetupHandler.setupCard(accessCode: selectedAccessCode, in: cardSession)
            log("Start loading order info")
            try await cardActivationOrderProvider.provideActivationOrderForSign()

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
}

private extension CommonVisaActivationManager {
    func startCardSession() async throws -> CardSession {
        if await authorizationTokenHandler.containsAccessToken {
            log("Access token exists, flow not implemented")
            try await cardActivationOrderProvider.provideActivationOrderForSign()
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
