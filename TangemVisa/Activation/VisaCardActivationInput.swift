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
    public let isAccessCodeSet: Bool

    public init(cardId: String, cardPublicKey: Data, isAccessCodeSet: Bool) {
        self.cardId = cardId
        self.cardPublicKey = cardPublicKey
        self.isAccessCodeSet = isAccessCodeSet
    }
}

public enum VisaCardActivationStatus: Codable {
    case activated(authTokens: VisaAuthorizationTokens)
    case activationStarted(activationInput: VisaCardActivationInput, authTokens: VisaAuthorizationTokens, activationRemoteState: VisaCardActivationRemoteState)
    case notStartedActivation(activationInput: VisaCardActivationInput)
    case blocked

    public var authTokens: VisaAuthorizationTokens? {
        switch self {
        case .activated(let authTokens):
            return authTokens
        case .activationStarted(_, let authTokens, _):
            return authTokens
        case .notStartedActivation, .blocked:
            return nil
        }
    }

    public var activationInput: VisaCardActivationInput? {
        switch self {
        case .activated, .blocked:
            return nil
        case .activationStarted(let activationInput, _, _):
            return activationInput
        case .notStartedActivation(let activationInput):
            return activationInput
        }
    }

    public var isActivated: Bool {
        activationInput == nil
    }
}

public enum VisaCardActivationRemoteState: String, Codable {
    case cardWalletSignatureRequired
    case customerWalletSignatureRequired
    case paymentAccountDeploying
    case waitingPinCode
    case waitingForActivationFinishing
    case activated
    case blockedForActivation
}
