//
//  OSLogFileWriter.swift
//  TangemApp
//
//  Created by Sergey Balashov on 22.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import OSLog

extension OSLogCategory {
    static let logFileWriter = OSLogCategory(name: "LogFileWriter")
}

class OSLogFileWriter {
    static let shared = OSLogFileWriter()

    private let loggerSerialQueue = DispatchQueue(label: "com.tangem.OSLogFileWriter.queue")

    private lazy var fileManager: FileManager = .default

    private lazy var logFileURL: URL = fileManager
        .urls(for: .cachesDirectory, in: .userDomainMask)[0]
        .appendingPathComponent(OSLogConstants.fileName)

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter
    }()

    private lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss:SSS '/' ZZZZ"
        return formatter
    }()

    private init() {
        try? removeLogFileIfNeeded()
        try? createLogFileIfNeeded()
    }
}

// MARK: - Internal

extension OSLogFileWriter {
    var logFile: URL { logFileURL }

    func write(_ message: String, category: OSLog.Category, level: OSLog.Level, date: Date = .now) throws {
        var message = message.trimmingCharacters(in: .whitespacesAndNewlines)

        if message.contains("\n") {
            try message.components(separatedBy: "\n").forEach {
                try write($0, category: category, level: level, date: date)
            }
            return
        }

        assert(!message.contains("\n"), "Should be separated by a few messages")

        if message.isEmpty {
            // Message can not be empty
            return
        }

        message = message
            // The symbol `,` will be replaced to `¸`
            .replacingOccurrences(of: OSLogConstants.separator, with: OSLogConstants.cedilla)
            // Should checked above but replace it just in case
            .replacingOccurrences(of: "\n", with: "@new-line@")

        let entry = OSLogEntry(
            date: dateFormatter.string(from: date),
            time: timeFormatter.string(from: date),
            category: category.name,
            level: level.name,
            message: message
        )

        let row = "\n\(entry.encoded(separator: OSLogConstants.separator))"
        try write(row: row)
    }
}

// MARK: - Private

private extension OSLogFileWriter {
    func write(row: String) throws {
        try loggerSerialQueue.sync {
            guard let data = row.data(using: .utf8) else {
                throw Errors.wrongRow
            }

            let handler = try FileHandle(forWritingTo: logFileURL)
            try handler.seekToEnd()
            try handler.write(contentsOf: data)
            try handler.close()
        }
    }

    func createLogFileIfNeeded() throws {
        guard !fileManager.fileExists(atPath: logFileURL.relativePath) else {
            return
        }

        fileManager.createFile(atPath: logFileURL.relativePath, contents: nil)

        // OSLogEntry property names
        let header = OSLogEntry.encodedHeader(separator: OSLogConstants.separator)
        try write(row: header)
    }

    func removeLogFileIfNeeded() throws {
        let fileAttributes = try fileManager.attributesOfItem(atPath: logFileURL.relativePath)

        guard let creationDate = fileAttributes[.creationDate] as? Date,
              let expirationDate = Calendar.current.date(byAdding: .day, value: OSLogConstants.numberOfDaysUntilExpiration, to: creationDate),
              expirationDate < Date() else {
            return
        }

        try fileManager.removeItem(at: logFileURL)
    }
}

// MARK: - Errors

extension OSLogFileWriter {
    enum Errors: LocalizedError {
        case wrongRow

        var errorDescription: String? {
            switch self {
            case .wrongRow: "Wrong row"
            }
        }
    }
}
