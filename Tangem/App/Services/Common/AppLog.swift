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

struct TangemSdkOSLogger: TangemSdkLogger {
    func log(_ message: String, level: Log.Level) {
        let prefix = level.prefix.isEmpty ? level.emoji : "\(level.emoji):\(level.prefix)"

        Logger.debug(.tangemSDK, "\(prefix) \(message)")
    }
}

class AppLog {
    static let shared = AppLog()

    let fileLogger = FileLogger()

    private init() {}

    var sdkLogConfig: Log.Config {
        var loggers: [TangemSdkLogger] = [ /* fileLogger */ ]

        if AppEnvironment.current.isDebug {
            loggers.append(TangemSdkOSLogger())
        }

        return .custom(
            logLevel: [.warning, .error, .command, .debug, .nfc, .session, .network],
            loggers: loggers
        )
    }

    func configure() {
        Log.config = sdkLogConfig
        fileLogger.removeLogFileIfNeeded()
    }

    func debug<T>(_ message: @autoclosure () -> T) {
        TangemLogger.Logger.debug(.custom("Common"), message())
    }

    // TODO: Andrey Fedorov - Get rid of this method and pass file/line as arguments to `debug` (IOS-6440)
    func debugDetailed<T>(file: StaticString = #fileID, line: UInt = #line, _ message: @autoclosure () -> T) {
        Log.debug("\(file):\(line): \(message())")
    }

    func logAppLaunch(_ currentLaunch: Int) {
        let sessionMessage = "New session. Session id: \(AppConstants.sessionId)"
        let launchNumberMessage = "Current launch number: \(currentLaunch)"
        let deviceInfoMessage = "\(DeviceInfoProvider.Subject.allCases.map { $0.description }.joined(separator: ", "))"
        Logger.info(.app, sessionMessage, launchNumberMessage, deviceInfoMessage)
    }
}

extension AppLog: VisaLogger {
    func error(_ error: any Error) {
        Analytics.error(error)
    }
}
