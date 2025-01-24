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
    var isAccessCodeSet: Bool { get }
    var isContinuingActivation: Bool { get }
    var activationStatus: VisaCardActivationStatus { get }
    var activationRemoteState: VisaCardActivationRemoteState { get }

    func saveAccessCode(accessCode: String) throws (VisaAccessCodeValidationError)
    func resetAccessCode()
    func setupRefreshTokenSaver(_ refreshTokenSaver: VisaRefreshTokenSaver)

    func startActivation() async throws (VisaActivationError)
    func refreshActivationRemoteState() async throws (VisaActivationError) -> VisaCardActivationRemoteState

    func setPINCode(_ pinCode: String) async throws (VisaActivationError)
}

public protocol VisaAccessCodeValidator: AnyObject {
    func validateAccessCode(accessCode: String) throws (VisaAccessCodeValidationError)
}

final class CommonVisaActivationManager {
    public private(set) var activationStatus: VisaCardActivationStatus

    public private(set) var targetApproveAddress: String?

    public var activationRemoteState: VisaCardActivationRemoteState {
        switch activationStatus {
        case .activated:
            return .activated
        case .activationStarted(_, _, let activationRemoteState):
            return activationRemoteState
        case .notStartedActivation:
            return .cardWalletSignatureRequired
        case .blocked:
            return .blockedForActivation
        }
    }

    private var selectedAccessCode: String?

    private let authorizationService: VisaAuthorizationService
    private let authorizationTokenHandler: AuthorizationTokenHandler
    private let tangemSdk: TangemSdk

    private let authorizationProcessor: CardAuthorizationProcessor
    private let cardActivationOrderProvider: CardActivationOrderProvider
    private let cardActivationRemoteStateService: VisaCardActivationRemoteStateService
    private let otpRepository: VisaOTPRepository

    private let logger: InternalLogger

    private var activationTask: AnyCancellable?

    private var cardInput: VisaCardActivationInput? {
        activationStatus.activationInput
    }

    init(
        initialActivationStatus: VisaCardActivationStatus,
        authorizationService: VisaAuthorizationService,
        authorizationTokenHandler: AuthorizationTokenHandler,
        tangemSdk: TangemSdk,
        authorizationProcessor: CardAuthorizationProcessor,
        cardActivationOrderProvider: CardActivationOrderProvider,
        cardActivationRemoteStateService: VisaCardActivationRemoteStateService,
        otpRepository: VisaOTPRepository,
        logger: InternalLogger
    ) {
        activationStatus = initialActivationStatus

        self.authorizationService = authorizationService
        self.authorizationTokenHandler = authorizationTokenHandler
        self.tangemSdk = tangemSdk

        self.authorizationProcessor = authorizationProcessor
        self.cardActivationOrderProvider = cardActivationOrderProvider
        self.cardActivationRemoteStateService = cardActivationRemoteStateService
        self.otpRepository = otpRepository

        self.logger = logger
    }

    private func log<T>(_ message: @autoclosure () -> T) {
        logger.debug(subsystem: .activationManager, message())
    }
}

extension CommonVisaActivationManager: VisaActivationManager {
    var isAccessCodeSet: Bool {
        guard let cardInput else {
            return true
        }

        return cardInput.isAccessCodeSet
    }

    var isContinuingActivation: Bool {
        if case .notStartedActivation = activationStatus {
            return false
        }

        return true
    }

    func validateAccessCode(accessCode: String) throws (VisaAccessCodeValidationError) {
        guard accessCode.count >= 4 else {
            throw .accessCodeIsTooShort
        }
    }

    func saveAccessCode(accessCode: String) throws (VisaAccessCodeValidationError) {
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
        switch activationStatus {
        case .activated:
            throw .alreadyActivated
        case .activationStarted(let activationInput, let authorizationTokens, let state):
            guard state == .cardWalletSignatureRequired else {
                throw .invalidActivationState
            }

            try await continueActivation(activationInput: activationInput, authorizationTokens: authorizationTokens)
        case .notStartedActivation(let activationInput):
            guard let selectedAccessCode else {
                throw .missingAccessCode
            }

            try await startFullActivationFlow(activationInput: activationInput, withAccessCode: selectedAccessCode)
        case .blocked:
            throw .blockedForActivation
        }
    }

    func refreshActivationRemoteState() async throws (VisaActivationError) -> VisaCardActivationRemoteState {
        guard let authorizationTokens = await authorizationTokenHandler.authorizationTokens else {
            throw .missingAccessToken
        }

        guard let cardInput else {
            throw .invalidActivationState
        }

        let loadedState: VisaCardActivationRemoteState
        do {
            try await Task.sleep(seconds: 3)
            loadedState = try await cardActivationRemoteStateService.loadCardActivationRemoteState(authorizationTokens: authorizationTokens)
        } catch {
            throw .underlyingError(error)
        }

        guard loadedState != activationRemoteState else {
            return loadedState
        }

        updateActivationStatus(
            toState: loadedState,
            using: cardInput,
            authorizationTokens: authorizationTokens
        )

        return loadedState
    }

    func setPINCode(_ pinCode: String) async throws (VisaActivationError) {
        guard
            let cardInput,
            let authorizationTokens = await authorizationTokenHandler.authorizationTokens
        else {
            throw .missingAccessToken
        }

        // TODO: IOS-8572 implement saving pin code on issuer
        try? await Task.sleep(seconds: 3)

        updateActivationStatus(toState: .waitingForActivationFinishing, using: cardInput, authorizationTokens: authorizationTokens)
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
                guard let cardInput = manager.cardInput else {
                    throw VisaActivationError.alreadyActivated
                }

                let tokens = try await manager.authorizationProcessor.getAccessToken(
                    signedChallenge: signedAuthorizationChallenge.cardSignature,
                    salt: signedAuthorizationChallenge.salt,
                    cardInput: cardInput
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

private extension CommonVisaActivationManager {
    func startFullActivationFlow(
        activationInput: VisaCardActivationInput,
        withAccessCode accessCode: String
    ) async throws (VisaActivationError) {
        do {
            var authorizationChallenge: String?
            if await !authorizationTokenHandler.containsAccessToken {
                authorizationChallenge = try await authorizationProcessor.getAuthorizationChallenge(for: activationInput)
            }

            let task = CardActivationTask(
                selectedAccessCode: accessCode,
                activationInput: activationInput,
                challengeToSign: authorizationChallenge,
                delegate: self,
                otpRepository: otpRepository,
                logger: logger
            )

            let activationResponse: CardActivationResponse = try await withCheckedThrowingContinuation { [weak self] continuation in
                guard let self else {
                    continuation.resume(throwing: "Deinitialized")
                    return
                }

                tangemSdk.startSession(with: task, cardId: activationInput.cardId) { result in
                    switch result {
                    case .success(let response):
                        continuation.resume(with: .success(response))
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }

            let newInput = VisaCardActivationInput(
                cardId: activationInput.cardId,
                cardPublicKey: activationInput.cardPublicKey,
                isAccessCodeSet: true
            )

            guard let tokens = await authorizationTokenHandler.authorizationTokens else {
                throw VisaActivationError.missingAccessToken
            }

            updateActivationStatus(
                toState: .cardWalletSignatureRequired,
                using: newInput,
                authorizationTokens: tokens
            )

            try await handleCardActivation(using: activationResponse)
        } catch {
            log("Failed to activate card. Generic error: \(error)")
            throw .underlyingError(error)
        }
    }

    func continueActivation(
        activationInput: VisaCardActivationInput,
        authorizationTokens: VisaAuthorizationTokens
    ) async throws (VisaActivationError) {
        do {
            if activationInput.isAccessCodeSet {
                try await signActivationOrder(activationInput: activationInput)
            } else {
                guard let selectedAccessCode else {
                    throw VisaActivationError.missingAccessCode
                }

                try await startFullActivationFlow(activationInput: activationInput, withAccessCode: selectedAccessCode)
            }
        } catch let activationError as VisaActivationError {
            throw activationError
        } catch {
            throw .underlyingError(error)
        }
    }

    func signActivationOrder(activationInput: VisaCardActivationInput) async throws {
        let activationOrder = try await cardActivationOrderProvider.provideActivationOrderForSign()

        let signTask = SignActivationOrderTask(orderToSign: activationOrder)
        let signedActivationOrder: SignedActivationOrder = try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else {
                continuation.resume(throwing: "Deinitialized")
                return
            }

            tangemSdk.startSession(with: signTask, cardId: activationInput.cardId) { result in
                switch result {
                case .success(let signedOrder):
                    continuation.resume(returning: signedOrder)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }

        let otp: Data
        if let storedOTP = otpRepository.getOTP(cardId: activationInput.cardId) {
            otp = storedOTP
        } else {
            log("Failed to find stored OTP in repository. Continuing activation without OTP.")
            otp = Data()
        }

        try await handleCardActivation(using: .init(signedActivationOrder: signedActivationOrder, rootOTP: otp))
    }

    func handleCardActivation(using activationResponse: CardActivationResponse) async throws {
        log("Do something with activation response: \(activationResponse)")
        // TODO: IOS-8576
        // TODO: Remove after backend integration
        targetApproveAddress = "0x9F65354e595284956599F2892fA4A4a87653D6E6"
    }
}

private extension CommonVisaActivationManager {
    func updateActivationStatus(
        toState state: VisaCardActivationRemoteState,
        using input: VisaCardActivationInput,
        authorizationTokens: VisaAuthorizationTokens?
    ) {
        guard let authorizationTokens else {
            activationStatus = .notStartedActivation(activationInput: input)
            return
        }

        switch state {
        case .cardWalletSignatureRequired:
            if input.isAccessCodeSet {
                activationStatus = .activationStarted(
                    activationInput: input,
                    authTokens: authorizationTokens,
                    activationRemoteState: state
                )
            } else {
                activationStatus = .notStartedActivation(activationInput: input)
            }
        case .blockedForActivation:
            activationStatus = .blocked
        case .activated:
            activationStatus = .activated(authTokens: authorizationTokens)
        case .customerWalletSignatureRequired, .paymentAccountDeploying, .waitingForActivationFinishing, .waitingPinCode:
            activationStatus = .activationStarted(
                activationInput: input,
                authTokens: authorizationTokens,
                activationRemoteState: state
            )
        }
    }
}
