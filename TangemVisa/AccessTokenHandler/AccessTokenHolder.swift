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

    func setTokens(_ tokens: DecodedAuthorizationJWTTokens) async {
        jwtTokens = tokens
    }

    func setTokens(authorizationTokens: VisaAuthorizationTokens) async throws {
        jwtTokens = try AuthorizationTokensDecoderUtility().decodeAuthTokens(authorizationTokens)
    }

    func getTokens() async -> DecodedAuthorizationJWTTokens? {
        jwtTokens
    }
}
