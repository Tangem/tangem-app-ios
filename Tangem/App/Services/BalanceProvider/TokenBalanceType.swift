//
//  TokenBalanceType.swift
//  TangemApp
//
//  Created by Sergey Balashov on 25.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - TokenBalanceType

enum TokenBalanceType: Hashable {
    // No derivation / Don't start loading yet
    case empty(EmptyReason)
    // "Skeleton" or "New animation"
    case loading(Cached?)
    // "Cached" or "-"
    // The date on which the balance would be relevant
    case failure(Cached?)
    // All good
    case loaded(Decimal)
}

// MARK: - TokenBalanceType+

extension TokenBalanceType {
    static let noAccount = TokenBalanceType.loaded(0)

    var value: Decimal? {
        switch self {
        case .empty: nil
        case .loading(let cached): cached?.balance
        case .failure(let cached): cached?.balance
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

extension TokenBalanceType: CustomStringConvertible {
    var description: String {
        switch self {
        case .empty(let reason): "Empty \(reason)"
        case .loading(let cached): "Loading cached: \(String(describing: cached))"
        case .failure(let cached): "Failure cached: \(String(describing: cached))"
        case .loaded(let balance): "Loaded: \(balance)"
        }
    }
}

// MARK: - Models

extension TokenBalanceType {
    enum EmptyReason: Hashable {
        case noDerivation
        case noData
        case custom
    }

    struct Cached: Hashable {
        let balance: Decimal
        let date: Date
    }
}
