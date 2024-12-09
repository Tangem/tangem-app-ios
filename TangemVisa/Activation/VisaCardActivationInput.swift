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
