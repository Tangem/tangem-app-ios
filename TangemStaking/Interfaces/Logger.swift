//
//  Logger.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 27.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol Logger {
    func error(_ error: Error)
    func debug<T>(_ message: @autoclosure () -> T)
}
