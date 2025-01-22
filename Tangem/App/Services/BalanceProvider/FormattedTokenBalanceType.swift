//
//  FormattedTokenBalanceType.swift
//  TangemApp
//
//  Created by Sergey Balashov on 25.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - FormattedTokenBalanceType

enum FormattedTokenBalanceType: Hashable {
    // "Skeleton" or "New animation"
    case loading(CachedType)
    // "Cached" or "-"
    // The date on which the balance would be relevant
    case failure(CachedType)
    // All good
    case loaded(String)
}

// MARK: - FormattedTokenBalanceType+

extension FormattedTokenBalanceType {
    var value: String {
        switch self {
        case .loading(let cached): cached.value
        case .failure(let cached): cached.value
        case .loaded(let value): value
        }
    }

    var isLoading: Bool {
        switch self {
        case .loading: true
        default: false
        }
    }

    var isFailure: Bool {
        switch self {
        case .failure: true
        default: false
        }
    }
}

// MARK: - CustomStringConvertible

extension FormattedTokenBalanceType: CustomStringConvertible {
    var description: String {
        switch self {
        case .loading(let cached): "Loading cached balance: \(String(describing: cached))"
        case .failure(let cached): "Failure cached balance: \(String(describing: cached))"
        case .loaded: "Loaded balance"
        }
    }
}

// MARK: - Cached

extension FormattedTokenBalanceType {
    enum CachedType: Hashable {
        case empty(String)
        case cache(Cached)

        var value: String {
            switch self {
            case .empty(let value): value
            case .cache(let cached): cached.balance
            }
        }
    }

    struct Cached: Hashable, CustomStringConvertible {
        let balance: String
        let date: Date

        var description: String {
            "Cached balance on date: \(date.formatted())"
        }
    }
}
