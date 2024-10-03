//
//  CommonExpressAnalyticsLogger.swift
//  TangemExpress
//
//  Created by Alexander Osokin on 05.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct CommonExpressAnalyticsLogger: ExpressAnalyticsLogger {
    func bestProviderSelected(_ provider: ExpressAvailableProvider) {
        print("Best provider selected: \(provider.provider.name)")
    }
}
