//
//  ExpressAnalyticsLogger.swift
//  TangemExpress
//
//  Created by Alexander Osokin on 05.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol ExpressAnalyticsLogger {
    // Swap
    func bestProviderSelected(_ provider: ExpressAvailableProvider)

    // Onramp
    func logAppError(_ error: Error, provider: ExpressProvider)
    func logExpressAPIError(_ error: ExpressAPIError, provider: ExpressProvider, paymentMethod: OnrampPaymentMethod)
}
