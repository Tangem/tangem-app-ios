//
//  LogsComposer.swift
//  Tangem
//
//  Created by Alexander Osokin on 25.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

class LogsComposer {
    private let providers: [LogFileProvider]

    init(providers: [LogFileProvider]) {
        self.providers = providers
    }

    convenience init(infoProvider: LogFileProvider) {
        let providers = [infoProvider, OSLogFileProvider()]
        self.init(providers: providers)
    }

    func getLogFiles() -> [URL] {
        return providers.map { $0.prepareLogFile() }
    }

    func getLogsData() -> [String: Data] {
        return providers.reduce(into: [:]) { result, provider in
            if let logData = provider.logData {
                result[provider.fileName] = logData
            }
        }
    }
}
