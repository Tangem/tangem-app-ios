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

struct VisaCardActivationResponse {
    let signedOrderByCard: Data
    let signedOrderByWallet: Data
    let rootOTP: Data
}

protocol SignedAuthorizationChallengeDelegate: AnyObject {
    func challengeSigned(signedChallenge: Data, salt: Data, completion: @escaping (Result<Void, Error>) -> Void)
}

final class CardActivationTask: CardSessionRunnable {
    typealias CompletionHandler = CompletionResult<VisaCardActivationResponse>

    private weak var activationOrderProvider: CardActivationOrderProvider?
    private weak var signedAuthorizationChallengeDelegate: SignedAuthorizationChallengeDelegate?
    private let logger: InternalLogger

    private let activationInput: VisaCardActivationInput
    private let challengeToSign: String?

    private var taskCancellationError: TangemSdkError?
    private var orderLoadingTask: Task<Void, Error>?
    private var rootOTP: Data?

    private var orderPublisher = CurrentValueSubject<String?, Never>(nil)
    private var orderSubscription: AnyCancellable?

    init(
        activationInput: VisaCardActivationInput,
        challengeToSign: String?,
        orderToSign: String?,
        activationOrderProvider: CardActivationOrderProvider,
        signedAuthorizationChallengeDelegate: SignedAuthorizationChallengeDelegate,
        logger: InternalLogger
    ) {
        self.activationInput = activationInput
        self.challengeToSign = challengeToSign
        orderPublisher.send(orderToSign)

        self.activationOrderProvider = activationOrderProvider
        self.signedAuthorizationChallengeDelegate = signedAuthorizationChallengeDelegate
        self.logger = logger
    }

    func run(in session: CardSession, completion: @escaping CompletionHandler) {
        guard let card = session.environment.card else {
            completion(.failure(TangemSdkError.missingPreflightRead))
            return
        }

        guard card.cardId.caseInsensitiveCompare(activationInput.cardId) == .orderedSame else {
            completion(.failure(.underlying(error: VisaCardActivationError.wrongCard)))
            return
        }
    }

    private func log<T>(_ message: @autoclosure () -> T) {
        logger.debug(subsystem: .cardActivationTask, message())
    }
}

// MARK: - Card Activation Flow

private extension CardActivationTask {
    func signAuthorizationChallenge(in session: CardSession, completion: @escaping CompletionHandler) {
        guard let challengeToSign else {
            loadOrderChallenge()
            createWallet(in: session, completion: completion)
            return
        }

        let attestationCommand = AttestCardKeyCommand(challenge: Data(hexString: challengeToSign))
        attestationCommand.run(in: session) { result in
            switch result {
            case .success(let response):
                self.signedAuthorizationChallengeDelegate?.challengeSigned(
                    signedChallenge: response.cardSignature,
                    salt: response.salt
                ) { [weak self] result in
                    switch result {
                    case .success(let success):
                        self?.loadOrderChallenge()
                    case .failure(let error):
                        self?.taskCancellationError = .underlying(error: error)
                    }
                }
                self.createWallet(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func createWallet(in session: CardSession, completion: @escaping CompletionHandler) {
        let utils = VisaUtilities(isTestnet: false)

        if let taskCancellationError {
            completion(.failure(taskCancellationError))
            return
        }

        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

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

        let generateCommand = GenerateOTPCommand()
        generateCommand.run(in: session) { result in
            switch result {
            case .success(let response):
                self.rootOTP = response.rootOTP
                self.waitForOrder(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func waitForOrder(in session: CardSession, completion: @escaping CompletionHandler) {
        if let taskCancellationError {
            completion(.failure(taskCancellationError))
            return
        }

        if let orderToSign = orderPublisher.value {
            signOrderWithCard(in: session, orderToSign: orderToSign, completion: completion)
        } else {
            guard orderSubscription == nil else {
                return
            }

            orderSubscription = orderPublisher
                .compactMap { $0 }
                .sink(receiveValue: { [weak self] orderToSign in
                    self?.signOrderWithCard(in: session, orderToSign: orderToSign, completion: completion)
                    self?.orderSubscription = nil
                })
        }
    }
}

// MARK: - Order signing

private extension CardActivationTask {
    func setupAccessCode(in session: CardSession, completion: @escaping CompletionHandler) {}

    func signOrderWithCard(in session: CardSession, orderToSign: String, completion: @escaping CompletionHandler) {
        let dataToSign = ActivationOrderGenerator().generateOrder(using: orderToSign)

        let attestCardCommand = AttestCardKeyCommand(challenge: dataToSign)
        attestCardCommand.run(in: session) { result in
            switch result {
            case .success(let response):
                self.signOrderWithWallet(
                    in: session,
                    dataToSign: dataToSign,
                    signedOrderByCard: response,
                    completion: completion
                )
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func signOrderWithWallet(
        in session: CardSession,
        dataToSign: Data,
        signedOrderByCard: AttestCardKeyResponse,
        completion: @escaping CompletionHandler
    ) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        let utils = VisaUtilities(isTestnet: false)
        guard let wallet = card.wallets.first(where: { $0.curve == utils.mandatoryCurve }) else {
            completion(.failure(.underlying(error: VisaCardActivationError.missingWallet)))
            return
        }

        let signCommand = SignHashCommand(hash: dataToSign, walletPublicKey: wallet.publicKey)
        signCommand.run(in: session) { result in
            switch result {
            case .success(let signResponse):
                guard let rootOTP = self.rootOTP else {
                    completion(.failure(.underlying(error: VisaCardActivationError.missingRootOTP)))
                    return
                }

                completion(.success(.init(
                    signedOrderByCard: signResponse.signature,
                    signedOrderByWallet: signedOrderByCard.cardSignature,
                    rootOTP: rootOTP
                )))
            case .failure(let error):
                completion(.failure(.underlying(error: error)))
            }
        }
    }
}

// MARK: - Order loading

private extension CardActivationTask {
    func loadOrderChallenge() {
        guard orderLoadingTask == nil else {
            log("Order loading task already in progress, no need to create another one")
            return
        }

        orderLoadingTask = Task { [weak self] in
            guard let self else { return }

            do {
                guard let orderToSign = try await activationOrderProvider?.provideActivationOrderForSign() else {
                    throw VisaCardActivationError.missingActivationOrderProvider
                }

                orderPublisher.send(orderToSign)
            } catch {
                log("Failed to get data. Cancelling task")
                taskCancellationError = .underlying(error: error)
            }

            orderLoadingTask = nil
        }
    }
}

public enum VisaCardActivationError: String, Error {
    case wrongCard
    case missingOrderDataToSign
    case missingWallet
    case missingActivationOrderProvider
    case missingRootOTP
}

struct ActivationOrderGenerator {
    func generateOrder(using orderInfo: String) -> Data {
        orderInfo.data(using: .utf8) ?? Data()
    }
}
