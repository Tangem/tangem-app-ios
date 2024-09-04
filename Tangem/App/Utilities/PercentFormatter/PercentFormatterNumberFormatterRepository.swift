//
//  PercentFormatterNumberFormatterRepository.swift
//  Tangem
//
//  Created by Andrey Fedorov on 29.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// Creates new (if needed) and caches existing `NumberFormatter` instances.
final class PercentFormatterNumberFormatterRepository {
    static let shared = PercentFormatterNumberFormatterRepository()

    private let cache = NSCacheWrapper<CacheKey, NumberFormatter>()

    private init() {}

    func numberFormatter(
        locale: Locale,
        option: PercentFormatter.Option,
        uniqueIdentifier: String? = nil
    ) -> NumberFormatter? {
        let cacheKey = CacheKey(
            uniqueIdentifier: uniqueIdentifier,
            localeIdentifier: locale.identifier,
            formattingOptions: option
        )

        return cache.value(forKey: cacheKey)
    }

    func storeNumberFormatter(
        _ numberFormatter: NumberFormatter,
        locale: Locale,
        option: PercentFormatter.Option,
        uniqueIdentifier: String? = nil
    ) {
        let cacheKey = CacheKey(
            uniqueIdentifier: uniqueIdentifier,
            localeIdentifier: locale.identifier,
            formattingOptions: option
        )

        cache.setValue(numberFormatter, forKey: cacheKey)
    }
}

// MARK: - Auxiliary types

private extension PercentFormatterNumberFormatterRepository {
    struct CacheKey: Hashable {
        let uniqueIdentifier: String?
        let localeIdentifier: String
        let formattingOptions: PercentFormatter.Option
    }
}
