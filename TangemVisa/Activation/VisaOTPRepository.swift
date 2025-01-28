//
//  OTPRepository.swift
//  TangemVisa
//
//  Created by Andrew Son on 11.12.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

protocol VisaOTPRepository: AnyObject {
    func hasSavedOTP(cardId: String) -> Bool
    func getOTP(cardId: String) -> GenerateOTPResponse?
    func saveOTP(_ otp: GenerateOTPResponse, cardId: String)
    func removeOTP(cardId: String)
}

final class CommonVisaOTPRepository: VisaOTPRepository {
    private var otpDict = [String: GenerateOTPResponse]()

    func hasSavedOTP(cardId: String) -> Bool {
        return getOTP(cardId: cardId) != nil
    }

    func getOTP(cardId: String) -> GenerateOTPResponse? {
        return otpDict[cardId]
    }

    func saveOTP(_ otp: GenerateOTPResponse, cardId: String) {
        otpDict[cardId] = otp
    }

    func removeOTP(cardId: String) {
        otpDict[cardId] = nil
    }
}
