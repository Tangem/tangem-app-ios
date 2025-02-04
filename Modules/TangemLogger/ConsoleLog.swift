//
//  ConsoleLog.swift
//  TangemModules
//
//  Created by Sergey Balashov on 04.02.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

/// The `ConsoleLog` was created for `DEBUG` and will not work under other conditions
/// It allows you to use all the useful functions of `Logger` instead of the usual "print`
public let ConsoleLog = Logger(category: .console)

extension OSLogCategory {
    static let console = OSLogCategory(name: "Console")
}
