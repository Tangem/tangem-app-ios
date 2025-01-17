//
//  ExpressAnalyticsLoggerMock.swift
//  TangemApp
//
//  Created by Sergey Balashov on 12.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemExpress

struct ExpressAnalyticsLoggerMock: ExpressAnalyticsLogger {
    func bestProviderSelected(_ provider: TangemExpress.ExpressAvailableProvider) {}

    func logAppError(_ error: any Error, provider: TangemExpress.ExpressProvider) {}

    func logExpressAPIError(_ error: ExpressAPIError, provider: ExpressProvider, paymentMethod: OnrampPaymentMethod) {}
}
