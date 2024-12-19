//
//  AccessTokenHolder.swift
//  TangemApp
//
//  Created by Andrew Son on 15.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

actor AccessTokenHolder {
    private var jwtTokens: DecodedAuthorizationJWTTokens?
    private var authTokens: VisaAuthorizationTokens?

    var tokens: DecodedAuthorizationJWTTokens? {
        get async {
            jwtTokens
        }
    }

    var authorizationTokens: VisaAuthorizationTokens? {
        get async {
            authTokens
        }
    }

    func setTokens(_ tokens: DecodedAuthorizationJWTTokens) async {
        jwtTokens = tokens
    }

    func setTokens(authorizationTokens: VisaAuthorizationTokens) async throws {
        authTokens = authorizationTokens
        try await setTokens(AuthorizationTokensUtility().decodeAuthTokens(authorizationTokens))
    }
}
