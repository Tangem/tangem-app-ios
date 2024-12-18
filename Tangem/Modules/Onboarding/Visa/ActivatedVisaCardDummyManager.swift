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

    func saveAccessCode(accessCode: String) throws {}

    func resetAccessCode() {}

    func setupRefreshTokenSaver(_ refreshTokenSaver: any TangemVisa.VisaRefreshTokenSaver) {}

    func startActivation() async throws {}

    func validateAccessCode(accessCode: String) throws {}
}
