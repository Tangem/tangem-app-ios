//
//  CardActivationTask.swift
//  TangemVisa
//
//  Created by Andrew Son on 27.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

struct CardActivationResponse {
    let signedActivationOrder: SignedActivationOrder
    let rootOTP: Data
}

protocol CardActivationTaskOrderProvider: AnyObject {
    func getOrderForSignedChallenge(
        signedAuthorizationChallenge: AttestCardKeyResponse,
        completion: @escaping (Result<CardActivationOrder, Error>) -> Void
    )
    func getActivationOrder(completion: @escaping (Result<CardActivationOrder, Error>) -> Void)
}

final class CardActivationTask: CardSessionRunnable {
    typealias CompletionHandler = CompletionResult<CardActivationResponse>

    private weak var orderProvider: CardActivationTaskOrderProvider?
    private weak var otpRepository: VisaOTPRepository?
    private let logger: InternalLogger

    private let selectedAccessCode: String
    private let activationInput: VisaCardActivationInput
    private let challengeToSign: String?

    private var taskCancellationError: TangemSdkError?

    private var orderPublisher = CurrentValueSubject<CardActivationOrder?, Never>(nil)

    init(
        selectedAccessCode: String,
        activationInput: VisaCardActivationInput,
        challengeToSign: String?,
        delegate: CardActivationTaskOrderProvider,
        otpRepository: VisaOTPRepository,
        logger: InternalLogger
    ) {
        self.selectedAccessCode = selectedAccessCode
        self.activationInput = activationInput
        self.challengeToSign = challengeToSign
        orderPublisher.send(nil)

        orderProvider = delegate
        self.otpRepository = otpRepository
        self.logger = logger
    }

    func run(in session: CardSession, completion: @escaping CompletionHandler) {
        guard let card = session.environment.card else {
            completion(.failure(TangemSdkError.missingPreflightRead))
            return
        }

        guard card.cardId.caseInsensitiveCompare(activationInput.cardId) == .orderedSame else {
            completion(.failure(.underlying(error: VisaActivationError.wrongCard)))
            return
        }

        if let challengeToSign {
            let challengeDataToSign = Data(hexString: challengeToSign)
            signAuthorizationChallenge(challengeToSign: challengeDataToSign, in: session, completion: completion)
        } else {
            getActivationOrder(in: session, completion: completion)
        }
    }

    private func log<T>(_ message: @autoclosure () -> T) {
        logger.debug(subsystem: .cardActivationTask, message())
    }
}

// MARK: - Card Activation Flow

private extension CardActivationTask {
    func signAuthorizationChallenge(challengeToSign: Data, in session: CardSession, completion: @escaping CompletionHandler) {
        let attestationCommand = AttestCardKeyCommand(challenge: challengeToSign)
        attestationCommand.run(in: session) { result in
            switch result {
            case .success(let response):
                self.processSignedAuthorizationChallenge(signResponse: response, in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func createWallet(in session: CardSession, completion: @escaping CompletionHandler) {
        if let taskCancellationError {
            completion(.failure(taskCancellationError))
            return
        }

        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        let utils = VisaUtilities(isTestnet: false)
        if card.wallets.contains(where: { $0.curve == utils.mandatoryCurve }) {
            createOTP(in: session, completion: completion)
            return
        }

        let createWallet = CreateWalletTask(curve: utils.mandatoryCurve)
        createWallet.run(in: session) { result in
            switch result {
            case .success:
                self.createOTP(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func createOTP(in session: CardSession, completion: @escaping CompletionHandler) {
        if let taskCancellationError {
            completion(.failure(taskCancellationError))
            return
        }

        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        guard let otpRepository else {
            completion(.failure(.underlying(error: VisaActivationError.missingOTPRepository)))
            return
        }

        do {
            if let otp = try otpRepository.getOTP(cardId: card.cardId) {
                waitForOrder(rootOTP: otp, in: session, completion: completion)
                return
            }
        } catch {
            log("Failed to get saved OTP: \(error)")
        }

        let otpCommand = GenerateOTPCommand()
        otpCommand.run(in: session) { result in
            switch result {
            case .success(let otpResponse):
                do {
                    try otpRepository.saveOTP(otpResponse.rootOTP, cardId: card.cardId)
                } catch {
                    self.log("Failed to save OTP in secure storage. Error: \(error)")
                }
                self.waitForOrder(rootOTP: otpResponse.rootOTP, in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func waitForOrder(rootOTP: Data, in session: CardSession, completion: @escaping CompletionHandler) {
        completion(.failure(.underlying(error: VisaActivationError.notImplemented)))
        // TODO: IOS-8572
    }
}

// MARK: - Order signing

private extension CardActivationTask {
    func signOrder(orderToSign: Data, in session: CardSession, completion: @escaping CompletionHandler) {
        let signOrderTask = SignActivationOrderTask(orderToSign: orderToSign)

        signOrderTask.run(in: session, completion: { result in
            switch result {
            case .success(let signedOrder):
                self.handleSignedActivationOrder(signedOrder, in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }

            withExtendedLifetime(signOrderTask) {}
        })
    }

    func handleSignedActivationOrder(
        _ signedOrder: SignedActivationOrder,
        in session: CardSession,
        completion: @escaping CompletionHandler
    ) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        do {
            guard let otp = try otpRepository?.getOTP(cardId: card.cardId) else {
                completion(.failure(.underlying(error: VisaActivationError.missingRootOTP)))
                return
            }

            let cardActivationResponse = CardActivationResponse(signedActivationOrder: signedOrder, rootOTP: otp)
            setupAccessCode(signResponse: cardActivationResponse, in: session, completion: completion)
        } catch {
            completion(.failure(.underlying(error: error)))
        }
    }

    func setupAccessCode(
        signResponse: CardActivationResponse,
        in session: CardSession,
        completion: @escaping CompletionHandler
    ) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        if card.isAccessCodeSet {
            completion(.success(signResponse))
            return
        }

        let setAccessCodeCommand = SetUserCodeCommand(accessCode: selectedAccessCode)
        setAccessCodeCommand.run(in: session) { result in
            switch result {
            case .success:
                completion(.success(signResponse))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Order loading related

private extension CardActivationTask {
    func processSignedAuthorizationChallenge(
        signResponse: AttestCardKeyResponse,
        in session: CardSession,
        completion: @escaping CompletionHandler
    ) {
        guard let orderProvider else {
            let missingDelegateError = VisaActivationError.taskMissingDelegate
            taskCancellationError = .underlying(error: missingDelegateError)
            completion(.failure(.underlying(error: missingDelegateError)))
            return
        }

        orderProvider.getOrderForSignedChallenge(signedAuthorizationChallenge: signResponse) { [weak self] result in
            self?.processActivationOrder(result)
        }
        createWallet(in: session, completion: completion)
    }

    func getActivationOrder(in session: CardSession, completion: @escaping CompletionHandler) {
        guard let orderProvider else {
            let missingDelegateError = VisaActivationError.taskMissingDelegate
            taskCancellationError = .underlying(error: missingDelegateError)
            completion(.failure(.underlying(error: missingDelegateError)))
            return
        }

        orderProvider.getActivationOrder { [weak self] result in
            self?.processActivationOrder(result)
        }
        createWallet(in: session, completion: completion)
    }

    func processActivationOrder(_ result: Result<CardActivationOrder, Error>) {
        switch result {
        case .success(let activationOrder):
            orderPublisher.send(activationOrder)
        case .failure(let error):
            taskCancellationError = .underlying(error: error)
        }
    }
}
