//
//  TangemLoggerConfigurator.swift
//  TangemApp
//
//  Created by Sergey Balashov on 26.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemLogger
import class TangemSdk.Log
import protocol TangemSdk.TangemSdkLogger

public let TSDKLogger = Logger(category: OSLogCategory(name: "TangemSDK", prefix: .none))

struct TangemLoggerConfigurator: Initializable {
    let tangemSDKLogConfig: Log.Config = .custom(
        logLevel: [.warning, .error, .command, .debug, .nfc, .session, .network],
        loggers: [TangemSDKLogger()]
    )

    func initialize() {
        Logger.configuration = TangemLoggerConfiguration()
        // TangemSDK logger
        Log.config = tangemSDKLogConfig
    }
}

// MARK: - TangemLogger.Configuration

struct TangemLoggerConfiguration: Logger.Configuration {
    func isLoggable() -> Bool {
        !AppEnvironment.current.isProduction
    }
}

// MARK: - TangemSDKLogger

struct TangemSDKLogger: TangemSdkLogger {
    func log(_ message: String, level: Log.Level) {
        let prefix = level.prefix.isEmpty ? level.emoji : "\(level.emoji)\(level.prefix)"

        switch level {
        case .error:
            TSDKLogger.error(error: "\(prefix) \(message)")
        case .warning:
            TSDKLogger.warning("\(prefix) \(message)")
        default:
            TSDKLogger.debug("\(prefix) \(message)")
        }
    }
}
