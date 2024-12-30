//
//  AppLog.swift
//  Tangem
//
//  Created by Alexander Osokin on 30.12.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemExpress
import TangemVisa
import TangemStaking

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
            logLevel: [.warning, .error, .command, .debug, .nfc, .session],
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

    // TODO: Andrey Fedorov - Get rid of this method and pass file/line as arguments to `debug` (IOS-6440)
    func debugDetailed<T>(file: StaticString = #fileID, line: UInt = #line, _ message: @autoclosure () -> T) {
        Log.debug("\(file):\(line): \(message())")
    }

    func error(_ error: Error) {
        self.error(error: error, params: [:])
    }

    func logAppLaunch(_ currentLaunch: Int) {
        let dashSeparator = String(repeating: "-", count: 25)
        let sessionMessage = "\(dashSeparator) New session. Session id: \(AppConstants.sessionId) \(dashSeparator)"
        let launchNumberMessage = "\(dashSeparator) Current launch number: \(currentLaunch) \(dashSeparator)"
        let deviceInfoMessage = "\(dashSeparator) \(DeviceInfoProvider.Subject.allCases.map { $0.description }.joined(separator: ", ")) \(dashSeparator)"
        debug("\n\(sessionMessage)\n\(launchNumberMessage)\n\(deviceInfoMessage)\n\n")
    }
}

extension AppLog: TangemExpress.Logger {}

extension AppLog: VisaLogger {}

extension AppLog: TangemStaking.Logger {}
