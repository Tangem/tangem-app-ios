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
    private let tokenItem: TokenItem

    init(tokenItem: TokenItem) {
        self.tokenItem = tokenItem
    }

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

    func logAppError(_ error: any Error, provider: ExpressProvider) {
        Analytics.log(
            event: .onrampAppErrors,
            params: [
                .token: tokenItem.currencySymbol,
                .provider: provider.name,
                .errorDescription: error.localizedDescription,
            ]
        )
    }

    func logExpressAPIError(_ error: ExpressAPIError, provider: ExpressProvider) {
        Analytics.log(
            event: .onrampErrors,
            params: [
                .token: tokenItem.currencySymbol,
                .provider: provider.name,
                .errorCode: error.errorCode.rawValue.description,
            ]
        )
    }
}
