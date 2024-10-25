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
        switch error {
        case let apiError as StakeKitAPIError:
            if let code = apiError.code {
                parameters[.errorCode] = code
            }
            if let message = apiError.message {
                parameters[.errorMessage] = message
            }
        case let httpError as StakeKitHTTPError:
            parameters[.errorDescription] = httpError.errorDescription
        // TODO: handle other errors separately
        default:
            break
        }
        Analytics.log(
            event: .stakingErrors,
            params: parameters
        )
    }
}
