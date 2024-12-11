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
    var targetApproveAddress: String? { get }

    func saveAccessCode(accessCode: String) throws
    func resetAccessCode()
    func setupRefreshTokenSaver(_ refreshTokenSaver: VisaRefreshTokenSaver)

    func startActivation() async throws
}

public protocol VisaAccessCodeValidator: AnyObject {
    func validateAccessCode(accessCode: String) throws
}

final class CommonVisaActivationManager {
    public private(set) var targetApproveAddress: String?
    private var selectedAccessCode: String?

    private let authorizationService: VisaAuthorizationService
    private let authorizationTokenHandler: AuthorizationTokenHandler
    private let tangemSdk: TangemSdk

    private let authorizationProcessor: CardAuthorizationProcessor
    private let cardActivationOrderProvider: CardActivationOrderProvider
    private let otpManager: OTPManager

    private let logger: InternalLogger

    private let cardInput: VisaCardActivationInput
    private var activationTask: AnyCancellable?

    init(
        cardInput: VisaCardActivationInput,
        authorizationService: VisaAuthorizationService,
        authorizationTokenHandler: AuthorizationTokenHandler,
        tangemSdk: TangemSdk,
        authorizationProcessor: CardAuthorizationProcessor,
        cardActivationOrderProvider: CardActivationOrderProvider,
        otpManager: OTPManager,
        logger: InternalLogger
    ) {
        self.cardInput = cardInput

        self.authorizationService = authorizationService
        self.authorizationTokenHandler = authorizationTokenHandler
        self.tangemSdk = tangemSdk

        self.authorizationProcessor = authorizationProcessor
        self.cardActivationOrderProvider = cardActivationOrderProvider
        self.otpManager = otpManager

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

    func startActivation() async throws (VisaActivationError) {
        guard let selectedAccessCode else {
            throw .missingAccessCode
        }

        try await taskActivation(accessCode: selectedAccessCode)
    }
}

// MARK: - Task implementation

extension CommonVisaActivationManager: CardActivationTaskOrderProvider {
    func getOrderForSignedChallenge(
        signedAuthorizationChallenge: AttestCardKeyResponse,
        completion: @escaping (Result<CardActivationOrder, any Error>) -> Void
    ) {
        runTask(in: self, isDetached: false) { manager in
            do {
                let tokens = try await manager.authorizationProcessor.getAccessToken(
                    signedChallenge: signedAuthorizationChallenge.cardSignature,
                    salt: signedAuthorizationChallenge.salt,
                    cardInput: manager.cardInput
                )
                try await manager.authorizationTokenHandler.setupTokens(tokens)
                let activationOrderResponse = try await manager.cardActivationOrderProvider.provideActivationOrderForSign()
                completion(.success(activationOrderResponse))
            } catch {
                manager.log("Failed to load authorization tokens: \(error)")
                completion(.failure(error))
            }
        }
    }

    func getActivationOrder(completion: @escaping (Result<CardActivationOrder, any Error>) -> Void) {
        runTask(in: self, isDetached: false) { manager in
            do {
                let activationOrder = try await manager.cardActivationOrderProvider.provideActivationOrderForSign()
                completion(.success(activationOrder))
            } catch {
                manager.log("Failed to load activation order. \nError:\(error)")
                completion(.failure(error))
            }
        }
    }
}

extension CommonVisaActivationManager {
    func taskActivation(accessCode: String) async throws (VisaActivationError) {
        do {
            var authorizationChallenge: String?
            if await !authorizationTokenHandler.containsAccessToken {
                authorizationChallenge = try await authorizationProcessor.getAuthorizationChallenge(for: cardInput)
            }

            let task = CardActivationTask(
                selectedAccessCode: accessCode,
                activationInput: cardInput,
                challengeToSign: authorizationChallenge,
                delegate: self,
                otpManager: otpManager,
                logger: logger
            )

            let activationResponse: VisaCardActivationResponse = try await withCheckedThrowingContinuation { [weak self] continuation in
                guard let self else {
                    continuation.resume(throwing: "Deinitialized")
                    return
                }

                tangemSdk.startSession(with: task, cardId: cardInput.cardId) { result in
                    switch result {
                    case .success(let response):
                        continuation.resume(with: .success(response))
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }

            log("Do something with activation response: \(activationResponse)")
            // TODO: - Remove after backend integration
            targetApproveAddress = "0x9F65354e595284956599F2892fA4A4a87653D6E6"
        } catch {
            log("Failed to activate card. Generic error: \(error)")
            throw .underlyingError(error)
        }
    }
}
