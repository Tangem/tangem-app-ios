//
//  VisaAuthorizationModels.swift
//  TangemVisa
//
//  Created by Andrew Son on 07.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct VisaAuthChallengeResponse: Decodable {
    public let nonce: String
    public let sessionId: String
}

public struct VisaAccessToken: Decodable {
    public let accessToken: String
    public let refreshToken: String
}
