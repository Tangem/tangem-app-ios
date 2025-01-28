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

public let AppLog = Logger(category: .app(.none))
public let WCLog = Logger(category: .app("Wallet Connect"))
public let AnalyticsLog = Logger(category: .analytics)
