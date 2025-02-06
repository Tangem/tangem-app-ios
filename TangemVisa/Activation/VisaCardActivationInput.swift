//
//  VisaCardActivationInput.swift
//  TangemVisa
//
//  Created by Andrew Son on 22.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public struct VisaCardActivationInput: Equatable, Codable {
    public let cardId: String
    public let cardPublicKey: Data
    public let isAccessCodeSet: Bool
    public let walletAddress: String?

    public init(cardId: String, cardPublicKey: Data, isAccessCodeSet: Bool, walletAddress: String? = nil) {
        self.cardId = cardId
        self.cardPublicKey = cardPublicKey
        self.isAccessCodeSet = isAccessCodeSet
        self.walletAddress = walletAddress
    }

    init(cardInput: VisaCardActivationInput, cardActivationResponse: CardActivationResponse, isTestnet: Bool = false) throws {
        cardId = cardInput.cardId
        cardPublicKey = cardInput.cardPublicKey
        isAccessCodeSet = true

        let visaUtilities = VisaUtilities(isTestnet: isTestnet)
        walletAddress = try visaUtilities.makeAddress(using: cardActivationResponse).value
    }
}

public enum VisaCardActivationLocalState: Codable {
    case activated(authTokens: VisaAuthorizationTokens)
    case activationStarted(activationInput: VisaCardActivationInput, authTokens: VisaAuthorizationTokens, activationStatus: VisaCardActivationStatus)
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

public struct VisaCardActivationStatus: Codable {
    public let activationRemoteState: VisaCardActivationRemoteState
    public let activationOrder: VisaCardActivationOrder

    private enum CodingKeys: String, CodingKey {
        case activationRemoteState = "activationStatus"
        case activationOrder
    }
}

public enum VisaCardActivationRemoteState: String, Codable, Equatable {
    case cardWalletSignatureRequired
    case customerWalletSignatureRequired
    case paymentAccountDeploying
    case waitingPinCode
    case waitingForActivationFinishing
    case activated
    case blockedForActivation
}

public struct VisaCardActivationOrder: Codable {
    public let id: String
    public let customerId: String
    public let customerWalletAddress: String
}
