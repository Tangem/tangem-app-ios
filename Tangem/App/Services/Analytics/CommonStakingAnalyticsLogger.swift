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
        let event: Analytics.Event
        var parameters: [Analytics.ParameterKey: String] = [.token: currencySymbol]
        switch error {
        case let apiError as StakeKitAPIError:
            if let code = apiError.code {
                parameters[.errorCode] = code
            }
            if let message = apiError.message {
                parameters[.errorMessage] = message
            }
            event = .stakingErrors
        case let httpError as StakeKitHTTPError:
            parameters[.errorDescription] = httpError.errorDescription
            event = .stakingErrors
        case let stakingManagerError as StakingManagerError:
            parameters[.errorDescription] = stakingManagerError.errorDescription
            event = .stakingAppErrors
        default: return
        }
        Analytics.log(
            event: event,
            params: parameters
        )
    }
}
