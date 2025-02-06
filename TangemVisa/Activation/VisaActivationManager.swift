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
    var activationLocalState: VisaCardActivationLocalState { get }
    var activationRemoteState: VisaCardActivationRemoteState { get }

    func saveAccessCode(accessCode: String) throws (VisaAccessCodeValidationError)
    func resetAccessCode()
    func setupRefreshTokenSaver(_ refreshTokenSaver: VisaRefreshTokenSaver)

    func startActivation() async throws (VisaActivationError) -> CardActivationResponse
    func refreshActivationRemoteState() async throws (VisaActivationError) -> VisaCardActivationRemoteState
    func getCustomerWalletApproveHash() async throws (VisaActivationError) -> Data
    func sendSignedCustomerWalletApprove(_ signedData: Data) async throws (VisaActivationError)

    func setPINCode(_ pinCode: String) async throws (VisaActivationError)
}

public protocol VisaAccessCodeValidator: AnyObject {
    func validateAccessCode(accessCode: String) throws (VisaAccessCodeValidationError)
}

final class CommonVisaActivationManager {
    public private(set) var activationLocalState: VisaCardActivationLocalState

    public private(set) var targetApproveAddress: String?

    public var activationRemoteState: VisaCardActivationRemoteState {
        switch activationLocalState {
        case .activated:
            return .activated
        case .activationStarted(_, _, let activationStatus):
            return activationStatus.activationRemoteState
        case .notStartedActivation:
            return .cardWalletSignatureRequired
        case .blocked:
            return .blockedForActivation
        }
    }

    private var selectedAccessCode: String?

    private let authorizationService: VisaAuthorizationService
    private let authorizationTokensHandler: AuthorizationTokensHandler
    private let tangemSdk: TangemSdk

    private let authorizationProcessor: CardAuthorizationProcessor
    private let cardActivationOrderProvider: CardActivationOrderProvider
    private let cardActivationStatusService: VisaCardActivationStatusService
    private let productActivationService: ProductActivationService
    private let otpRepository: VisaOTPRepository

    private let logger: InternalLogger

    private var activationTask: AnyCancellable?

    private var activationStatus: VisaCardActivationStatus? {
        switch activationLocalState {
        case .activated, .notStartedActivation, .blocked:
            return nil
        case .activationStarted(_, _, let activationStatus):
            return activationStatus
        }
    }

    private var activationInput: VisaCardActivationInput? {
        activationLocalState.activationInput
    }

    init(
        initialActivationStatus: VisaCardActivationLocalState,
        authorizationService: VisaAuthorizationService,
        authorizationTokensHandler: AuthorizationTokensHandler,
        tangemSdk: TangemSdk,
        authorizationProcessor: CardAuthorizationProcessor,
        cardActivationOrderProvider: CardActivationOrderProvider,
        cardActivationStatusService: VisaCardActivationStatusService,
        productActivationService: ProductActivationService,
        otpRepository: VisaOTPRepository,
        logger: InternalLogger
    ) {
        activationLocalState = initialActivationStatus

        self.authorizationService = authorizationService
        self.authorizationTokensHandler = authorizationTokensHandler
        self.tangemSdk = tangemSdk

        self.authorizationProcessor = authorizationProcessor
        self.cardActivationOrderProvider = cardActivationOrderProvider
        self.cardActivationStatusService = cardActivationStatusService
        self.productActivationService = productActivationService
        self.otpRepository = otpRepository

        self.logger = logger
    }

    private func log<T>(_ message: @autoclosure () -> T) {
        logger.debug(subsystem: .activationManager, message())
    }
}

extension CommonVisaActivationManager: VisaActivationManager {
    var isAccessCodeSet: Bool {
        guard let activationInput else {
            return true
        }

        return activationInput.isAccessCodeSet
    }

    var isContinuingActivation: Bool {
        if case .notStartedActivation = activationLocalState {
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
        authorizationTokensHandler.setupRefreshTokenSaver(refreshTokenSaver)
    }

    func startActivation() async throws (VisaActivationError) -> CardActivationResponse {
        switch activationLocalState {
        case .activated:
            throw .alreadyActivated
        case .activationStarted(let activationInput, let authorizationTokens, let status):
            guard status.activationRemoteState == .cardWalletSignatureRequired else {
                throw .invalidActivationState
            }

            return try await continueActivation(activationInput: activationInput, authorizationTokens: authorizationTokens)
        case .notStartedActivation(let activationInput):
            guard let selectedAccessCode else {
                throw .missingAccessCode
            }

            return try await startFullActivationFlow(activationInput: activationInput, withAccessCode: selectedAccessCode)
        case .blocked:
            throw .blockedForActivation
        }
    }

    func refreshActivationRemoteState() async throws (VisaActivationError) -> VisaCardActivationRemoteState {
        guard let authorizationTokens = await authorizationTokensHandler.authorizationTokens else {
            throw .missingAccessToken
        }

        guard let activationInput else {
            throw .invalidActivationState
        }

        let loadedStatus: VisaCardActivationStatus
        do {
            // TODO: IOS-8777 Will be removed during BFF integration tests
            try await Task.sleep(seconds: 3)
            loadedStatus = try await cardActivationStatusService.getCardActivationStatus(
                authorizationTokens: authorizationTokens,
                cardId: activationInput.cardId,
                cardPublicKey: activationInput.cardPublicKey.hexString
            )
        } catch {
            throw .underlyingError(error)
        }

        let loadedState = loadedStatus.activationRemoteState
        guard loadedState != activationRemoteState else {
            return loadedState
        }

        if case .activated = loadedState {
            try await saveActivatedCardRefreshToken()
        }

        updateActivationStatus(
            toState: loadedState,
            using: activationInput,
            authorizationTokens: authorizationTokens
        )

        return loadedState
    }

    func getCustomerWalletApproveHash() async throws (VisaActivationError) -> Data {
        guard let activationOrderId = activationStatus?.activationOrder.id else {
            throw .missingActivationStatusInfo
        }

        guard let walletAddress = activationInput?.walletAddress else {
            throw .missingWalletAddressInInput
        }

        log("Attempting to get challenge to approve by customer wallet")
        do {
            let customerWalletApproveResponse = try await productActivationService.getCustomerWalletDeployAcceptance(
                activationOrderId: activationOrderId,
                cardWalletAddress: walletAddress
            )
            return Data(hexString: customerWalletApproveResponse)
        } catch {
            log("Failed to load customer wallet approve hash. Error: \(error)")
            throw .underlyingError(error)
        }
    }

    func sendSignedCustomerWalletApprove(_ signedData: Data) async throws (VisaActivationError) {
        guard let activationInput else {
            throw .missingActivationInput
        }

        guard let activationOrder = activationStatus?.activationOrder else {
            throw .missingActivationStatusInfo
        }

        guard let authorizationTokens = await authorizationTokensHandler.authorizationTokens else {
            throw .missingAccessToken
        }

        log("Receive signed approve by customer wallet. Attempting to send it")
        do {
            try await productActivationService.sendSignedCustomerWalletDeployAcceptance(
                activationOrderId: activationOrder.id,
                customerWalletAddress: activationOrder.customerWalletAddress,
                deployAcceptanceSignature: signedData.hexString
            )
        } catch {
            log("Failed to send signed customer wallet approve data. Error: \(error)")
            throw .underlyingError(error)
        }

        updateActivationStatus(
            toState: .paymentAccountDeploying,
            using: activationInput,
            authorizationTokens: authorizationTokens
        )
    }

    func setPINCode(_ pinCode: String) async throws (VisaActivationError) {
        guard
            let activationInput,
            let authorizationTokens = await authorizationTokensHandler.authorizationTokens,
            let activationOrderId = activationStatus?.activationOrder.id
        else {
            throw .missingAccessToken
        }

        log("Attempting to send selected PIN code")
        do {
            try? await Task.sleep(seconds: 3)
            // TODO: IOS-9071 implement saving pin code on issuer
            try await productActivationService.sendSelectedPINCodeToIssuer(
                activationOrderId: activationOrderId,
                sessionKey: "IOS-9071",
                iv: "IOS-9071",
                encryptedPin: "IOS-9071"
            )
        } catch {
            log("Failed to send selected PIN to issuer. Error: \(error)")
            throw .underlyingError(error)
        }

        updateActivationStatus(toState: .waitingForActivationFinishing, using: activationInput, authorizationTokens: authorizationTokens)
    }
}

// MARK: - Task implementation

extension CommonVisaActivationManager: CardActivationTaskOrderProvider {
    func getOrderForSignedAuthorizationChallenge(
        signedAuthorizationChallenge: AttestCardKeyResponse,
        completion: @escaping (Result<VisaCardAcceptanceOrderInfo, any Error>) -> Void
    ) {
        runTask(in: self, isDetached: false) { manager in
            do {
                guard let cardInput = manager.activationInput else {
                    throw VisaActivationError.alreadyActivated
                }

                let tokens = try await manager.authorizationProcessor.getAccessToken(
                    signedChallenge: signedAuthorizationChallenge.cardSignature,
                    salt: signedAuthorizationChallenge.salt,
                    cardInput: cardInput
                )
                try await manager.authorizationTokensHandler.setupTokens(tokens)
                let activationOrderResponse = try await manager.cardActivationOrderProvider.provideActivationOrderForSign(activationInput: cardInput)
                completion(.success(activationOrderResponse))
            } catch {
                manager.log("Failed to load authorization tokens: \(error)")
                completion(.failure(error))
            }
        }
    }

    func getActivationOrder(completion: @escaping (Result<VisaCardAcceptanceOrderInfo, any Error>) -> Void) {
        runTask(in: self, isDetached: false) { manager in
            do {
                guard let cardInput = manager.activationInput else {
                    throw VisaActivationError.alreadyActivated
                }

                let activationOrder = try await manager.cardActivationOrderProvider.provideActivationOrderForSign(activationInput: cardInput)
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
    ) async throws (VisaActivationError) -> CardActivationResponse {
        do {
            var authorizationChallenge: String?
            if await !authorizationTokensHandler.containsAccessToken {
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

            let newInput = try VisaCardActivationInput(
                cardInput: activationInput,
                cardActivationResponse: activationResponse
            )

            guard let tokens = await authorizationTokensHandler.authorizationTokens else {
                throw VisaActivationError.missingAccessToken
            }

            activationLocalState = .activationStarted(
                activationInput: newInput,
                authTokens: tokens,
                activationStatus: .init(
                    activationRemoteState: .cardWalletSignatureRequired,
                    activationOrder: activationResponse.signedActivationOrder.order.activationOrder
                )
            )
            try await handleCardActivation(using: activationResponse, activationInput: newInput)
            return activationResponse
        } catch {
            log("Failed to activate card. Generic error: \(error)")
            throw .underlyingError(error)
        }
    }

    func continueActivation(
        activationInput: VisaCardActivationInput,
        authorizationTokens: VisaAuthorizationTokens
    ) async throws (VisaActivationError) -> CardActivationResponse {
        do {
            if activationInput.isAccessCodeSet {
                return try await signActivationOrder(activationInput: activationInput)
            } else {
                guard let selectedAccessCode else {
                    throw VisaActivationError.missingAccessCode
                }

                return try await startFullActivationFlow(activationInput: activationInput, withAccessCode: selectedAccessCode)
            }
        } catch let activationError as VisaActivationError {
            throw activationError
        } catch {
            throw .underlyingError(error)
        }
    }

    func signActivationOrder(activationInput: VisaCardActivationInput) async throws -> CardActivationResponse {
        let activationOrder = try await cardActivationOrderProvider.provideActivationOrderForSign(activationInput: activationInput)

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
        let otpCounter: Int
        if let storedOTP = otpRepository.getOTP(cardId: activationInput.cardId) {
            otp = storedOTP.rootOTP
            otpCounter = storedOTP.rootOTPCounter
        } else {
            log("Failed to find stored OTP in repository. Continuing activation without OTP.")
            otp = Data()
            otpCounter = 0
        }

        let activationResponse = CardActivationResponse(
            signedActivationOrder: signedActivationOrder,
            rootOTP: otp,
            rootOTPCounter: otpCounter
        )
        let newActivationInput = try VisaCardActivationInput(
            cardInput: activationInput,
            cardActivationResponse: activationResponse
        )
        try await handleCardActivation(using: activationResponse, activationInput: newActivationInput)
        return activationResponse
    }

    func handleCardActivation(using activationResponse: CardActivationResponse, activationInput: VisaCardActivationInput) async throws (VisaActivationError) {
        targetApproveAddress = activationResponse.signedActivationOrder.order.activationOrder.customerWalletAddress

        guard let tokens = await authorizationTokensHandler.authorizationTokens else {
            throw .missingAccessToken
        }

        guard let walletAddress = activationInput.walletAddress else {
            throw .missingWalletAddressInInput
        }

        log("Attempting to send deploy acceptance signed by card")
        do {
            let order = activationResponse.signedActivationOrder.order.activationOrder
            try await productActivationService.sendSignedVisaCardDeployAcceptance(
                activationOrderId: order.id,
                cardWalletAddress: walletAddress,
                signedAcceptance: activationResponse.signedActivationOrder.signedOrderByWallet.hexString,
                rootOtp: activationResponse.rootOTP.hexString,
                rootOtpCounter: activationResponse.rootOTPCounter
            )
        } catch {
            log("Failed to send deploy acceptance signed by card. Error: \(error)")
            throw .underlyingError(error)
        }

        activationLocalState = .activationStarted(
            activationInput: activationInput,
            authTokens: tokens,
            activationStatus: .init(
                activationRemoteState: .customerWalletSignatureRequired,
                activationOrder: activationResponse.signedActivationOrder.order.activationOrder
            )
        )
    }

    func saveActivatedCardRefreshToken() async throws (VisaActivationError) {
        do {
            try await authorizationTokensHandler.forceRefreshToken()
        } catch {
            log("Failed to retreive activated card refresh token. Error: \(error)")
            throw .underlyingError(error)
        }
    }
}

private extension CommonVisaActivationManager {
    func updateActivationStatus(
        toState state: VisaCardActivationRemoteState,
        using input: VisaCardActivationInput,
        authorizationTokens: VisaAuthorizationTokens?
    ) {
        // TODO: IOS-9087 - save activation status on device
        guard
            let authorizationTokens,
            let activationStatus
        else {
            activationLocalState = .notStartedActivation(activationInput: input)
            return
        }

        switch state {
        case .cardWalletSignatureRequired:
            if input.isAccessCodeSet {
                activationLocalState = .activationStarted(
                    activationInput: input,
                    authTokens: authorizationTokens,
                    activationStatus: .init(activationRemoteState: state, activationOrder: activationStatus.activationOrder)
                )
            } else {
                activationLocalState = .notStartedActivation(activationInput: input)
            }
        case .blockedForActivation:
            activationLocalState = .blocked
        case .activated:
            activationLocalState = .activated(authTokens: authorizationTokens)
        case .customerWalletSignatureRequired, .paymentAccountDeploying, .waitingForActivationFinishing, .waitingPinCode:
            activationLocalState = .activationStarted(
                activationInput: input,
                authTokens: authorizationTokens,
                activationStatus: .init(activationRemoteState: state, activationOrder: activationStatus.activationOrder)
            )
        }
    }
}
