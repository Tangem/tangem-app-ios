//
//  VisaCardActivationInput.swift
//  TangemVisa
//
//  Created by Andrew Son on 22.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct VisaCardActivationInput: Equatable, Codable {
    public let cardId: String
    public let cardPublicKey: Data

    public init(cardId: String, cardPublicKey: Data) {
        self.cardId = cardId
        self.cardPublicKey = cardPublicKey
    }
}

public enum VisaCardActivationStatus: Codable {
    case activated(authTokens: VisaAuthorizationTokens)
    case activationStarted(activationInput: VisaCardActivationInput, authTokens: VisaAuthorizationTokens)
    case notStartedActivation(activationInput: VisaCardActivationInput)

    public var authTokens: VisaAuthorizationTokens? {
        switch self {
        case .activated(let authTokens):
            return authTokens
        case .activationStarted(_, let authTokens):
            return authTokens
        case .notStartedActivation:
            return nil
        }
    }

    public var activationInput: VisaCardActivationInput? {
        switch self {
        case .activated:
            return nil
        case .activationStarted(let activationInput, _):
            return activationInput
        case .notStartedActivation(activationInput: let activationInput):
            return activationInput
        }
    }

    public var isActivated: Bool {
        activationInput == nil
    }
}
