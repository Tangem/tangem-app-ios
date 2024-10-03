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
    func logAPIError(errorDescription: String) {
        Analytics.log(event: .stakingErrors, params: [.errorDescription: errorDescription])
    }
}
