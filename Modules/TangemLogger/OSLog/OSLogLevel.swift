//
//  OSLogLevel.swift
//  TangemModules
//
//  Created by Sergey Balashov on 24.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public enum OSLogLevel: String, Hashable, CaseIterable {
    case debug
    case info
    case warning
    case error

    var name: String {
        switch self {
        case .debug: "Debug"
        case .info: "Info"
        case .warning: "Warning"
        case .error: "Error"
        }
    }
}
