//
//  AnalyticsContext.swift
//  Tangem
//
//  Created by Alexander Osokin on 07.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol AnalyticsContext {
    var contextData: AnalyticsContextData? { get }

    func setupContext(with: AnalyticsContextData)

    func clearContext()

    func value(forKey: AnalyticsStorageKey, scope: AnalyticsContextScope) -> Any?
    func set(value: Any, forKey storageKey: AnalyticsStorageKey, scope: AnalyticsContextScope)
    func removeValue(forKey storageKey: AnalyticsStorageKey, scope: AnalyticsContextScope)
}

// MARK: - DI

private struct AnalyticsContextKey: InjectionKey {
    static var currentValue: AnalyticsContext = CommonAnalyticsContext()
}

extension InjectedValues {
    var analyticsContext: AnalyticsContext {
        get { Self[AnalyticsContextKey.self] }
        set { Self[AnalyticsContextKey.self] = newValue }
    }
}
