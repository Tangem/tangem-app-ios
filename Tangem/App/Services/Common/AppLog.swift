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
import protocol TangemVisa.VisaLogger

class AppLog {
    static let shared = AppLog()
    let fileLogger = FileLogger()
    private init() {}

    func debug<T>(_ message: @autoclosure () -> T) {
        TangemLogger.Logger.debug(.custom("Common"), message())
    }
}

extension AppLog: VisaLogger {
    func error(_ error: any Error) {
        Analytics.error(error)
    }
}
