//
//  OnrampProviderManager.swift
//  TangemApp
//
//  Created by Sergey Balashov on 14.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public protocol OnrampProviderManager {
    /// Get actual state
    var state: OnrampProviderManagerState { get }

    /// Update quotes for amount
    func update(amount: Decimal?) async

    /// Build a request item with all fileds
    func makeOnrampQuotesRequestItem() throws -> OnrampQuotesRequestItem
}

public enum OnrampProviderManagerState: Hashable {
    case idle
    case notSupported(NotSupported)
    case loading
    case restriction(Restriction)
    case failed(error: String)
    case loaded(OnrampQuote)

    public var isSupported: Bool {
        switch self {
        case .idle, .loading, .failed, .loaded, .restriction: true
        case .notSupported: false
        }
    }

    public var isReadyToBuy: Bool {
        switch self {
        case .loaded: true
        case .idle, .loading, .failed, .notSupported, .restriction: false
        }
    }

    public var canBeShow: Bool {
        switch self {
        case .restriction, .loaded: true
        case .idle, .loading, .failed, .notSupported: false
        }
    }

    public enum Restriction: Hashable {
        case tooSmallAmount(_ minAmount: String)
        case tooBigAmount(_ maxAmount: String)
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
