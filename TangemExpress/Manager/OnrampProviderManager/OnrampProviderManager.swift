//
//  OnrampProviderManager.swift
//  TangemApp
//
//  Created by Sergey Balashov on 14.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public protocol OnrampProviderManager: Actor {
    /// Get actual state
    var state: OnrampProviderManagerState { get }

    /// Update quotes for amount
    func update(amount: Decimal) async
}

public enum OnrampProviderManagerState: Hashable {
    case created
    case notSupported(NotSupported)
    case loading
    case failed(error: String)
    case loaded(OnrampQuote)

    public var isSupported: Bool {
        switch self {
        case .created, .loading, .failed, .loaded: true
        case .notSupported: false
        }
    }

    public enum NotSupported: Hashable {
        case currentPair
        case paymentMethod
    }
}

public enum OnrampProviderManagerError: LocalizedError {
    case objectReleased
    case amountNotFound

    public var errorDescription: String? {
        switch self {
        case .objectReleased: "Object released"
        case .amountNotFound: "Wrong amount or amount not found"
        }
    }
}
