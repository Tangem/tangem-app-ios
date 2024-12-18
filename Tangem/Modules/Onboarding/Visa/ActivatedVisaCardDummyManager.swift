//
//  ActivatedVisaCardDummyManager.swift
//  Tangem
//
//  Created by Andrew Son on 12.12.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemVisa

/// This class should be used for activated card to go through Biometrics and Notification setup
class ActivatedVisaCardDummyManager: VisaActivationManager {
    var targetApproveAddress: String?

    var isAccessCodeSet: Bool { true }
    var isContinuingActivation: Bool { true }
    var activationStatus: TangemVisa.VisaCardActivationStatus {
        .activated(authTokens: .init(accessToken: "", refreshToken: ""))
    }

    func saveAccessCode(accessCode: String) throws (TangemVisa.VisaAccessCodeValidationError) {}

    func startActivation() async throws (TangemVisa.VisaActivationError) {}

    func validateAccessCode(accessCode: String) throws (TangemVisa.VisaAccessCodeValidationError) {}

    func resetAccessCode() {}

    func setupRefreshTokenSaver(_ refreshTokenSaver: any TangemVisa.VisaRefreshTokenSaver) {}
}
