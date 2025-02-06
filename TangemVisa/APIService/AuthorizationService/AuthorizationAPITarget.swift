//
//  AuthorizationAPITarget.swift
//  TangemVisa
//
//  Created by Andrew Son on 07.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct AuthorizationAPITarget: TargetType {
    let target: Target

    var baseURL: URL {
        return VisaConstants.bffBaseURL.appendingPathComponent("auth/")
    }

    var path: String {
        switch target {
        case .generateNonceByCID:
            return "card_id"
        case .generateNonceForWallet:
            return "card_wallet"
        case .getAccessTokenForCardAuth, .getAccessTokenForWalletAuth:
            return "get_token"
        case .refreshAccessToken:
            return "refresh_token"
        }
    }

    var method: Moya.Method {
        switch target {
        case .generateNonceByCID,
             .generateNonceForWallet,
             .refreshAccessToken,
             .getAccessTokenForCardAuth,
             .getAccessTokenForWalletAuth:
            return .post
        }
    }

    var task: Moya.Task {
        var params = [ParameterKey: Any]()

        switch target {
        case .generateNonceByCID(let cid, let cardPublicKey):
            params[.cardId] = cid
            params[.cardPublicKey] = cardPublicKey
        case .generateNonceForWallet(let cid, let walletAddress):
            params[.cardId] = cid
            params[.cardWalletAddress] = walletAddress
        case .getAccessTokenForCardAuth(let signature, let salt, let sessionId):
            params[.sessionId] = sessionId
            params[.signature] = signature
            params[.salt] = salt
        case .getAccessTokenForWalletAuth(let signature, let sessionId):
            params[.sessionId] = sessionId
            params[.signature] = signature
        case .refreshAccessToken(let refreshToken):
            params[.refreshToken] = refreshToken
        }

        return .requestParameters(parameters: params.dictionaryParams, encoding: URLEncoding.default)
    }

    var headers: [String: String]? {
        var params = VisaConstants.defaultHeaderParams
        params["Content-Type"] = "application/x-www-form-urlencoded"
        return params
    }
}

extension AuthorizationAPITarget {
    enum Target {
        case generateNonceByCID(cid: String, cardPublicKey: String)
        case generateNonceForWallet(cid: String, walletAddress: String)
        case getAccessTokenForCardAuth(signature: String, salt: String, sessionId: String)
        case getAccessTokenForWalletAuth(signature: String, sessionId: String)
        case refreshAccessToken(refreshToken: String)
    }
}

private extension AuthorizationAPITarget {
    enum ParameterKey: String {
        case cardId = "card_id"
        case cardPublicKey = "card_public_key"
        case cardWalletAddress = "card_wallet_address"
        case refreshToken = "refresh_token"
        case sessionId = "session_id"

        case signature
        case salt
    }
}

private extension Dictionary where Key == AuthorizationAPITarget.ParameterKey, Value == Any {
    var dictionaryParams: [String: Any] {
        var convertedParams = [String: Any]()
        forEach { convertedParams[$0.key.rawValue] = $0.value }
        return convertedParams
    }
}
