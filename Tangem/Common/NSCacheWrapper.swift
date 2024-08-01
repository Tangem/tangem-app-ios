//
//  NSCacheWrapper.swift
//  Tangem
//
//  Created by Andrey Fedorov on 23.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class NSCacheWrapper<Key, Value> where Key: Hashable {
    private let cache = NSCache<KeyWrapper<Key>, ValueWrapper<Value>>()

    func setValue(_ value: Value, forKey key: Key) {
        let valueWrapper = ValueWrapper(value: value)
        let keyWrapper = KeyWrapper(key: key)

        cache.setObject(valueWrapper, forKey: keyWrapper)
    }

    func value(forKey key: Key) -> Value? {
        let keyWrapper = KeyWrapper(key: key)
        let valueWrapper = cache.object(forKey: keyWrapper)

        return valueWrapper?.value
    }

    func removeValue(forKey key: Key) {
        let keyWrapper = KeyWrapper(key: key)

        cache.removeObject(forKey: keyWrapper)
    }

    func removeAllObjects() {
        cache.removeAllObjects()
    }
}

// MARK: - Auxiliary types

private extension NSCacheWrapper {
    final class KeyWrapper<T>: NSObject where T: Hashable {
        let key: T

        init(key: T) {
            self.key = key
        }

        override var hash: Int {
            return key.hashValue
        }

        override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? KeyWrapper<T> else {
                return false
            }

            return self === other || key == other.key
        }
    }

    final class ValueWrapper<T> {
        let value: T

        init(value: T) {
            self.value = value
        }
    }
}
