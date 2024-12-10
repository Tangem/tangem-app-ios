//
//  OnrampProviderManager.swift
//  TangemApp
//
//  Created by Sergey Balashov on 14.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public protocol OnrampProviderManager {
    /// Get actual from amount
    var amount: Decimal? { get }

    /// Get actual state
    var state: OnrampProviderManagerState { get }

    /// Update quotes for amount
    func update(amount: OnrampUpdatingAmount) async

    /// Build a request item with all fileds
    func makeOnrampQuotesRequestItem() throws -> OnrampQuotesRequestItem
}

// MARK: - OnrampProviderManagerState

public enum OnrampProviderManagerState {
    case idle
    case notSupported(NotSupported)
    case loading
    case restriction(Restriction)
    case failed(error: Error)
    case loaded(OnrampQuote)

    public var isSupported: Bool {
        switch self {
        case .idle, .loading, .failed, .loaded, .restriction: true
        case .notSupported: false
        }
    }

    public enum Restriction: Hashable, CustomStringConvertible {
        case tooSmallAmount(_ minAmount: String)
        case tooBigAmount(_ maxAmount: String)

        var amount: Decimal? {
            switch self {
            case .tooSmallAmount(let minAmount): Decimal(string: minAmount)
            case .tooBigAmount(let maxAmount): Decimal(string: maxAmount)
            }
        }

        public var description: String {
            switch self {
            case .tooSmallAmount(let minAmount): "Too small amount: \(minAmount)"
            case .tooBigAmount(let maxAmount): "Too big amount: \(maxAmount))"
            }
        }
    }

    public enum NotSupported: Hashable, CustomStringConvertible {
        case currentPair
        case paymentMethod(supportedMethods: [OnrampPaymentMethod])

        public var description: String {
            switch self {
            case .currentPair: "Current pair"
            case .paymentMethod: "Payment method"
            }
        }
    }
}

// MARK: - OnrampProviderManagerState + CustomStringConvertible

extension OnrampProviderManagerState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .idle: "Idle"
        case .notSupported(let type): "Not supported: \(type)"
        case .loading: "Loading"
        case .restriction(let restriction): "Restriction: \(restriction)"
        case .failed(error: let error): "Failed: \(error)"
        case .loaded(let quote): "Quote with amount: \(quote.expectedAmount)"
        }
    }
}

// MARK: - OnrampProviderManagerError

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
