//
//  OnrampProviderManager.swift
//  TangemApp
//
//  Created by Sergey Balashov on 14.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public protocol OnrampProviderManager: Actor {
    /// Update quotes for amount
    func update(amount: Decimal) async

    /// Get actual state
    func state() -> OnrampProviderManagerState
}

public enum OnrampProviderManagerState: Hashable {
    case created
    case notSupported(NotSupported)
    case loading
    case failed(error: String)
    case loaded(OnrampQuote)

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
