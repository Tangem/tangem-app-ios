//
//  AppLog.swift
//  Tangem
//
//  Created by Alexander Osokin on 30.12.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemLogger

let AppLog = Logger(category: .app)
let WCLog = Logger(category: .app).tag("Wallet Connect")
let AnalyticsLog = Logger(category: .analytics)

extension Logger.Category {
    static let app = OSLogCategory(name: "App")
    static let analytics = OSLogCategory(name: "Analytics", prefix: nil)
}
