//
//  AppLog.swift
//  Tangem
//
//  Created by Alexander Osokin on 30.12.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemSwapping

class AppLog {
    static let shared = AppLog()

    let fileLogger = FileLogger()

    private init() {}

    var sdkLogConfig: Log.Config {
        var loggers: [TangemSdkLogger] = [fileLogger]

        if AppEnvironment.current.isDebug {
            loggers.append(ConsoleLogger())
        }

        return .custom(
            logLevel: Log.Level.allCases,
            loggers: loggers
        )
    }

    func configure() {
        Log.config = sdkLogConfig
        fileLogger.removeLogFileIfNeeded()
    }

    func debug<T>(_ message: @autoclosure () -> T) {
        Log.debug(message())
    }

    func error(_ error: Error) {
        self.error(error: error, params: [:])
    }

    func logAppLaunch(_ currentLaunch: Int) {
        let dashSeparator = String(repeating: "-", count: 25)
        let launchNumberMessage = "\(dashSeparator) New session. Current launch number: \(currentLaunch) \(dashSeparator)"
        let deviceInfoMessage = "\(dashSeparator) \(DeviceInfoProvider.Subject.allCases.map { $0.description }.joined(separator: ", ")) \(dashSeparator)"
        debug("\n\(launchNumberMessage)\n\(deviceInfoMessage)\n\n")
    }
}

extension AppLog: SwappingLogger {}
