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
            parameters[.errorCode] = apiError.code
            parameters[.errorMessage] = apiError.message
            event = .stakingErrors
        case let httpError as StakeKitHTTPError:
            parameters[.errorDescription] = httpError.errorDescription
            event = .stakingErrors
        case let error as LocalizedError where error is StakingManagerError || error is StakeKitMapperError:
            parameters[.errorDescription] = error.errorDescription
            event = .stakingAppErrors
        default: return
        }
        Analytics.log(
            event: event,
            params: parameters
        )
    }
}
