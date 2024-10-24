//
//  Lock.swift
//  TangemFoundation
//
//  Created by Andrey Fedorov on 30/05/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public final class Lock {
    private let lock: NSLocking

    public init(isRecursive: Bool) {
        lock = isRecursive ? NSRecursiveLock() : NSLock()
    }

    public func withLock<R>(_ body: () throws -> R) rethrows -> R {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }

    public func callAsFunction<R>(_ body: () throws -> R) rethrows -> R {
        try withLock(body)
    }
}
