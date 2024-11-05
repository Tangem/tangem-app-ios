//
//  Lock.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 28.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

final class Lock {
    private let lock: NSLocking

    init(isRecursive: Bool) {
        lock = isRecursive ? NSRecursiveLock() : NSLock()
    }

    func withLock<R>(_ body: () throws -> R) rethrows -> R {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }

    func callAsFunction<R>(_ body: () throws -> R) rethrows -> R {
        try withLock(body)
    }
}
