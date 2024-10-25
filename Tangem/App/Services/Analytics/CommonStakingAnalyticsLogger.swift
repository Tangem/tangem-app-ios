//
//  CommonStakingAnalyticsLogger.swift
//  Tangem
//
//  Created by Dmitry Fedorov on 06.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

struct CommonStakingAnalyticsLogger: StakingAnalyticsLogger {
    func logError(_ error: any Error, currencySymbol: String) {
        var parameters: [Analytics.ParameterKey: String] = [.token: currencySymbol]
        switch error as? StakeKitAPIError {
        case .some(let error):
            if let code = error.code {
                parameters[.errorCode] = code
            }
            if let message = error.message {
                parameters[.errorMessage] = message
            }
        case .none:
            parameters[.errorDescription] = error.localizedDescription
        }
        Analytics.log(
            event: .stakingErrors,
            params: parameters
        )
    }
}
