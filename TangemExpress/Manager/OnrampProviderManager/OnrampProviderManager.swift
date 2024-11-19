//
//  OnrampProviderManager.swift
//  TangemApp
//
//  Created by Sergey Balashov on 14.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

// For every onramp provider
public protocol OnrampProviderManager: Actor {
    // Update quotes for amount
    func update(amount: Decimal) async

    // Get actual state
    func state() -> OnrampProviderManagerState
}

public enum OnrampProviderManagerState: Hashable {
    case created
    case loading
    case failed(String)
    case loaded([Loaded])

    public struct Loaded: Hashable {
        public let paymentMethod: OnrampPaymentMethod
        public let state: State

        public enum State: Hashable {
            case notSupported
            case failed(error: String)
            case quote(OnrampQuote)
        }
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
