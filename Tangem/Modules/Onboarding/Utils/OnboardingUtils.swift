//
//  OnboardingUtils.swift
//  Tangem
//
//  Created by Andrew Son on 27/01/25.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct OnboardingUtils {
    func requestBiometrics(responseHandler: @escaping (Bool) -> Void) {
        BiometricsUtil.requestAccess(localizedReason: Localization.biometryTouchIdReason) { result in
            let biometryAccessGranted: Bool
            switch result {
            case .failure(let error):
                if error.isUserCancelled {
                    return
                }

                AppLogger.error(error: error)

                biometryAccessGranted = false
            case .success:
                biometryAccessGranted = true
            }

            Analytics.log(.allowBiometricID, params: [
                .state: Analytics.ParameterValue.toggleState(for: biometryAccessGranted),
            ])

            responseHandler(biometryAccessGranted)
        }
    }

    func processSaveUserWalletRequestResult(agreed: Bool) {
        AppSettings.shared.askedToSaveUserWallets = true

        AppSettings.shared.saveUserWallets = agreed
        AppSettings.shared.saveAccessCodes = agreed

        Analytics.log(.onboardingEnableBiometric, params: [.state: Analytics.ParameterValue.toggleState(for: agreed)])
    }
}
