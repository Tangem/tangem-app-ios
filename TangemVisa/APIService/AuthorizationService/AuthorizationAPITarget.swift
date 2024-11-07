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

    private let clientId = "mobile-app-ios"

    var baseURL: URL {
        return URL(string: "https://api-s.tangem.org/")!
    }

    var path: String {
        switch target {
        case .generateNonceByCID:
            return "auth/clients/\(clientId)/nonce-challenge"
        case .getAccessToken, .refreshAccessToken:
            return "auth/protocol/openid-connect/token"
        }
    }

    var method: Moya.Method {
        switch target {
        case .generateNonceByCID, .refreshAccessToken, .getAccessToken:
            return .post
        }
    }

    var task: Moya.Task {
        var params = [ParameterKey: Any]()

        switch target {
        case .generateNonceByCID(let cid, let cardPublicKey):
            params[.cardId] = cid
            params[.cardPublicKey] = cardPublicKey
        case .getAccessToken(let signature, let sessionId):
            params[.clientId] = clientId
            params[.sessionId] = sessionId
            params[.signature] = signature
            params[.grantType] = GrantType.password
        case .refreshAccessToken(let refreshToken):
            params[.clientId] = clientId
            params[.grantType] = GrantType.refreshToken
            params[.refreshToken] = refreshToken
        }

        return .requestParameters(parameters: params.dictionaryParams, encoding: URLEncoding.default)
    }

    var headers: [String: String]? {
        return [
            "Content-Type": "application/x-www-form-urlencoded",
        ]
    }
}

extension AuthorizationAPITarget {
    enum Target {
        case generateNonceByCID(cid: String, cardPublicKey: String)
        case getAccessToken(signature: String, sessionId: String)
        case refreshAccessToken(refreshToken: String)
    }
}

private extension AuthorizationAPITarget {
    enum ParameterKey: String {
        case cardId = "card_id"
        case cardPublicKey = "card_public_key"
        case customerId = "customer_id"
        case refreshToken = "refresh_token"
        case sessionId = "session_id"
        case clientId = "client_id"
        case grantType = "grant_type"

        case signature
    }

    enum GrantType: String {
        case password
        case refreshToken = "refresh_token"
    }
}

private extension Dictionary where Key == AuthorizationAPITarget.ParameterKey, Value == Any {
    var dictionaryParams: [String: Any] {
        var convertedParams = [String: Any]()
        forEach { convertedParams[$0.key.rawValue] = $0.value }
        return convertedParams
    }
}
