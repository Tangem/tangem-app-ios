//
//  VisaActivationError.swift
//  TangemApp
//
//  Created by Andrew Son on 20.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum VisaActivationError: Error {}

public enum VisaAccessCodeValidationError: String, Error {
    case accessCodeIsTooShort
}
