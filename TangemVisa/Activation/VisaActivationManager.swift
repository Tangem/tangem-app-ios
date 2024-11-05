//
//  VisaActivationManager.swift
//  TangemVisa
//
//  Created by Andrew Son on 01.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol VisaActivationManager {
    func saveAccessCode(_ accessCode: String) throws
    func resetAccessCode()
}

class CommonVisaActivationManager {
    private var selectedAccessCode: String?
}

extension CommonVisaActivationManager: VisaActivationManager {
    func saveAccessCode(_ accessCode: String) throws {
        guard accessCode.count >= 4 else {
            throw VisaActivationError.accessCodeIsTooShort
        }

        selectedAccessCode = accessCode
    }

    func resetAccessCode() {
        selectedAccessCode = nil
    }
}

public struct VisaActivationManagerFactory {
    public init() {}

    public func make() -> VisaActivationManager {
        CommonVisaActivationManager()
    }
}

public enum VisaActivationError: String, Error {
    case accessCodeIsTooShort
}
