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

    private let customerInfoService: CustomerInfoService
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
        customerInfoService: CustomerInfoService,
        authorizationProcessor: CardAuthorizationProcessor,
        cardSetupHandler: CardSetupHandler,
        cardActivationOrderProvider: CardActivationOrderProvider,
        logger: InternalLogger
    ) {
        self.cardInput = cardInput

        self.authorizationService = authorizationService
        self.authorizationTokenHandler = authorizationTokenHandler

        self.customerInfoService = customerInfoService
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
            throw "Missing access code"
        }

        var cardSession: CardSession?

        do {
            cardSession = try await startCardSession()
            guard let cardSession else {
                log("Failed to find active NFC session")
                throw "Failed to find active NFC session"
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
        } catch {
            log("Failed to finish activation. Reason: \(error)")
            log("Stopping NFC session")
            cardSession?.stop()
            log("Canceling card setup")
            cardSetupHandler.cancelCardSetup()
            log("Canceling loading of card activation order")
            cardActivationOrderProvider.cancelOrderLoading()
            log("Failed to activate Visa card")
            throw error
        }
    }
}

private extension CommonVisaActivationManager {
    func startCardSession() async throws -> CardSession {
        if await authorizationTokenHandler.containsAccessToken {
            throw "Access token exists, flow not implemented."
        } else {
            log("Authorization tokens not found, starting authorization process")
            let cardAuthorizationResult = try await authorizationProcessor.authorizeCard(with: cardInput)
            log("Authorization process successfully finished. Received access tokens and session")
            try await authorizationTokenHandler.setupTokens(cardAuthorizationResult.authorizationTokens)
            return cardAuthorizationResult.cardSession
        }
    }
}
