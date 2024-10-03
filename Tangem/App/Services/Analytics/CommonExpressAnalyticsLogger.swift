//
//  ExpressAnalyticsLogger.swift
//  Tangem
//
//  Created by Alexander Osokin on 05.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct CommonExpressAnalyticsLogger: ExpressAnalyticsLogger {
    func bestProviderSelected(_ provider: ExpressAvailableProvider) {
        guard provider.provider.id.lowercased() == "changelly",
              provider.provider.recommended == true else {
            return
        }

        Analytics.log(
            .promoChangellyActivity,
            params: [.state: provider.isBest ? .native : .recommended]
        )
    }
}
