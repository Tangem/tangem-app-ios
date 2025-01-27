//
//  LogFileProvider.swift
//  Tangem
//
//  Created by Alexander Osokin on 25.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemLogger

protocol LogFileProvider {
    var fileName: String { get }
    var logData: Data? { get }
    func prepareLogFile() -> URL
}

enum LogFilesNames {
    static let infoLogs = "infoLogs.txt"
}

struct OSLogFileProvider: LogFileProvider {
    var fileName: String {
        OSLogFileParser.logFile.lastPathComponent
    }

    var logData: Data? {
        try? Data(contentsOf: OSLogFileParser.logFile)
    }

    func prepareLogFile() -> URL {
        OSLogFileParser.logFile
    }
}
