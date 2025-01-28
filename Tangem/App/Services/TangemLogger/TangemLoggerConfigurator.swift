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

public let TSDKLogger = Logger(category: .tangemSDK)

struct TangemLoggerConfigurator: Initializable {
    let tangemSDKLogConfig: Log.Config = .custom(
        logLevel: [.warning, .error, .command, .debug, .nfc, .session, .network],
        loggers: [TangemSDKLogger()]
    )

    func initialize() {
        Logger.configuration = TangemLoggerConfiguration()
        Logger.prefixBuilder = TangemLoggerPrefixBuilder()
        // TangemSDK logger
        Log.config = tangemSDKLogConfig
    }
}

// MARK: - TangemLogger.Configuration

struct TangemLoggerConfiguration: Logger.Configuration {
    func shouldStore(category: TangemLogger.Logger.Category, level: TangemLogger.Logger.Level) -> Bool {
        !AppEnvironment.current.isProduction
    }

    func shouldPrint(category: Logger.Category, level: Logger.Level) -> Bool {
        !AppEnvironment.current.isProduction
    }
}

// MARK: - TangemLogger.PrefixBuilder

struct TangemLoggerPrefixBuilder: Logger.PrefixBuilder {
    let defaultPrefixBuilder = Logger.DefaultPrefixBuilder()

    func prefix(category: Logger.Category, level: Logger.Level, option: Logger.PrefixOption) -> String? {
        switch category {
        case .analytics, .tangemSDK, .network:
            return nil
        default:
            return defaultPrefixBuilder.prefix(category: category, level: level, option: option)
        }
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
