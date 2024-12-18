//
//  VisaAuthorizationService.swift
//  TangemVisa
//
//  Created by Andrew Son on 05.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

public protocol VisaAuthorizationService {
    func getCardAuthorizationChallenge(cardId: String, cardPublicKey: String) async throws -> VisaAuthChallengeResponse
    func getWalletAuthorizationChallenge(cardId: String, walletPublicKey: String) async throws -> VisaAuthChallengeResponse
    func getAccessTokensForCardAuth(
        signedChallenge: String,
        salt: String,
        sessionId: String
    ) async throws -> VisaAuthorizationTokens
    func getAccessTokensForWalletAuth(signedChallenge: String, sessionId: String) async throws -> VisaAuthorizationTokens?
}

protocol AccessTokenRefreshService {
    func refreshAccessToken(refreshToken: String) async throws -> VisaAuthorizationTokens
}

class CommonVisaAuthorizationService {
    private let apiService: APIService<AuthorizationAPITarget, VisaAuthorizationAPIError>

    init(
        provider: MoyaProvider<AuthorizationAPITarget>,
        logger: InternalLogger
    ) {
        apiService = .init(
            provider: provider,
            logger: logger,
            decoder: JSONDecoderFactory().makePayAPIDecoder()
        )
    }
}

extension CommonVisaAuthorizationService: VisaAuthorizationService {
    func getCardAuthorizationChallenge(cardId: String, cardPublicKey: String) async throws -> VisaAuthChallengeResponse {
        try await apiService.request(.init(
            target: .generateNonceByCID(cid: cardId, cardPublicKey: cardPublicKey)
        ))
    }

    func getWalletAuthorizationChallenge(cardId: String, walletPublicKey: String) async throws -> VisaAuthChallengeResponse {
        try await apiService.request(.init(
            target: .generateNonceForWallet(cid: cardId, walletPublicKey: walletPublicKey)
        ))
    }

    func getAccessTokensForCardAuth(
        signedChallenge: String,
        salt: String,
        sessionId: String
    ) async throws -> VisaAuthorizationTokens {
        try await apiService.request(.init(
            target: .getAccessTokenForCardAuth(signature: signedChallenge, salt: salt, sessionId: sessionId)
        ))
    }

    func getAccessTokensForWalletAuth(signedChallenge: String, sessionId: String) async throws -> VisaAuthorizationTokens? {
        try await apiService.request(.init(
            target: .getAccessTokenForWalletAuth(signature: signedChallenge, sessionId: sessionId)
        ))
    }
}

extension CommonVisaAuthorizationService: AccessTokenRefreshService {
    func refreshAccessToken(refreshToken: String) async throws -> VisaAuthorizationTokens {
        try await apiService.request(.init(
            target: .refreshAccessToken(refreshToken: refreshToken)
        ))
    }
}
