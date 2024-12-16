//
//  Logger.swift
//  TangemExpress
//
//  Created by Alexander Osokin on 30.12.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public protocol Logger {
    func error(_ error: Error)
    func debug<T>(_ message: @autoclosure () -> T)
}
