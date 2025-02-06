//
//  OSLogFileParser.swift
//  TangemModules
//
//  Created by Sergey Balashov on 23.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum OSLogFileParser {
    public static let logFile: URL = OSLogFileWriter.shared.logFile

    public static func entries(logFile: URL = OSLogFileParser.logFile) throws -> [OSLogEntry] {
        let content = try String(contentsOf: logFile)
        let rows: [String] = content.components(separatedBy: "\n")

        return rows
            .dropFirst() // Drop Header
            .compactMap { row in
                let components = row.components(separatedBy: OSLogConstants.separator)
                guard components.count == 5 else {
                    assertionFailure("Wrong OSLogEntry format")
                    return nil
                }

                return OSLogEntry(
                    date: components[0],
                    time: components[1],
                    category: components[2],
                    level: components[3],
                    message: components[4]
                )
            }
    }
}
