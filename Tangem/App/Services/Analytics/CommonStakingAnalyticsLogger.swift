//
//  CommonStakingAnalyticsLogger.swift
//  Tangem
//
//  Created by Dmitry Fedorov on 06.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import BlockchainSdk

struct CommonStakingAnalyticsLogger: StakingAnalyticsLogger {
    private let token: TokenItem?
    
    init(token: TokenItem? = nil) {
        self.token = token
    }
    
    func logAPIError(errorDescription: String) {
        var params: [Analytics.ParameterKey: String] = [.errorDescription: errorDescription]
        if let token {
            params[.token] = token.currencySymbol
        }
        Analytics.log(event: .stakingErrors, params: params)
    }
}
