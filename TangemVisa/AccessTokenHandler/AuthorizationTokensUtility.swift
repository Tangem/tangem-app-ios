//
//  AuthorizationTokensUtility.swift
//  TangemApp
//
//  Created by Andrew Son on 15.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import JWTDecode

struct AuthorizationTokensUtility {
    func decodeAuthTokens(_ tokens: VisaAuthorizationTokens) throws -> DecodedAuthorizationJWTTokens {
        let accessToken = try decode(jwt: tokens.accessToken)
        let refreshToken = try decode(jwt: tokens.refreshToken)
        return .init(accessToken: accessToken, refreshToken: refreshToken)
    }

    func getAuthorizationHeader(from tokens: VisaAuthorizationTokens) -> String {
        return VisaConstants.authorizationHeaderValuePrefix + tokens.accessToken
    }

    func getAuthorizationHeader(from tokens: DecodedAuthorizationJWTTokens) -> String {
        return VisaConstants.authorizationHeaderValuePrefix + tokens.accessToken.string
    }
}

struct DecodedAuthorizationJWTTokens {
    var accessToken: JWT
    var refreshToken: JWT
}
