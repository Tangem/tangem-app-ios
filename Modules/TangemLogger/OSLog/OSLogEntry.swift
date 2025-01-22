//
//  OSLogMessage.swift
//  TangemModules
//
//  Created by Sergey Balashov on 23.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public struct OSLogEntry: Hashable {
    public let date: String
    public let time: String
    public let category: String
    public let level: String
    public let message: String

    static func encodedHeader(separator: String) -> String {
        ["Date", "Time", "Category", "Level", "Message"]
            .joined(separator: separator)
    }

    func encoded(separator: String) -> String {
        let data = [date, time, category, level, message]
        return data.joined(separator: separator)
    }
}
