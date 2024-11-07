//
//  VisaCardScanHandler.swift
//  Tangem
//
//  Created by Andrew Son on 06.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemVisa

class VisaCardScanHandler {
    private let authorizationService: VisaAuthorizationService

    init() {
        let builder = VisaAPIServiceBuilder()
        authorizationService = builder.buildAuthorizationService(urlSessionConfiguration: .defaultConfiguration, logger: AppLog.shared)
    }

    deinit {
        log("Scan handler deinitialized")
    }

    func handleVisaCardScan(session: CardSession, completion: @escaping CompletionResult<DefaultWalletData>) {
        log("Attempting to handle Visa card scan")
        Task(priority: .userInitiated) { [weak self] in
            self?.log("Running task for Visa card scan")
            await self?.handleVisaCardScanAsync(session: session, completion: completion)
        }
    }

    private func handleVisaCardScanAsync(session: CardSession, completion: @escaping CompletionResult<DefaultWalletData>) async {
        log("Started handling visa card scan async")
        guard let card = session.environment.card else {
            log("Failed to find card in session environment")
            completion(.failure(TangemSdkError.missingPreflightRead))
            return
        }

        do {
            log("Requesting authorization challenge to sign")
            let challengeResponse = try await authorizationService.getAuthorizationChallenge(
                //                cardId: card.cardId,
                cardId: "FF00000000000061",
                cardPublicKey: card.cardPublicKey.hexString
            )
            log("Received challenge to sign: \(challengeResponse)")

            let signedChallenge = try await signChallenge(session: session, challenge: challengeResponse.nonce)
            log("Challenged signed. Result: \(signedChallenge.hexString)")
            let accessTokenResponse = try await authorizationService.getAccessTokens(
                signedChallenge: signedChallenge.hexString,
                sessionId: challengeResponse.sessionId
            )
            log("Access token response: \(accessTokenResponse)")

            let visaWalletData = DefaultWalletData.visa(
                accessToken: accessTokenResponse.accessToken,
                refreshToken: accessTokenResponse.refreshToken
            )
            completion(.success(visaWalletData))
        } catch let error as TangemSdkError {
            log("Failed to handle challenge signing. Tangem SDK error: \(error.localizedDescription)")
            completion(.failure(error))
        } catch {
            log("Failed to handle challenge signing. Plain error: \(error.localizedDescription)")
            completion(.failure(TangemSdkError.underlying(error: error)))
        }
    }

    private func signChallenge(session: CardSession, challenge: String) async throws -> Data {
        try await withCheckedThrowingContinuation { [session] continuation in
            let data = Data(hexString: challenge)
            let signTask = AttestCardKeyCommand(challenge: data)
            signTask.run(in: session) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response.cardSignature)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func log<T>(_ message: @autoclosure () -> T) {
        AppLog.shared.debug("[Visa Card Scan Handler] \(message())")
    }
}
