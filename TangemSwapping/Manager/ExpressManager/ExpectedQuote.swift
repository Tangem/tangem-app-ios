//
//  ExpectedQuote.swift
//  TangemSwapping
//
//  Created by Sergey Balashov on 10.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpectedQuote: Hashable {
    public let provider: ExpressProvider
    public let state: State
    public let isBest: Bool

    public var quote: ExpressQuote? {
        switch state {
        case .quote(let expressQuote):
            return expressQuote
        case .error, .notAvailable, .tooSmallAmount:
            return nil
        }
    }

    public var isAvailable: Bool {
        switch state {
        case .quote:
            return true
        case .error, .notAvailable, .tooSmallAmount:
            return false
        }
    }

    public var isError: Bool {
        switch state {
        case .error, .tooSmallAmount:
            return true
        case .quote, .notAvailable:
            return false
        }
    }

    public var rate: Decimal {
        if let quote, !quote.fromAmount.isZero {
            return quote.expectAmount / quote.fromAmount
        }

        return 0
    }

    init(provider: ExpressProvider, state: State, isBest: Bool) {
        self.provider = provider
        self.isBest = isBest
        self.state = state
    }
}

public extension ExpectedQuote {
    enum State: Hashable {
        case quote(ExpressQuote)
        case error(String)
        case notAvailable
        case tooSmallAmount(minAmount: Decimal)

        public var quote: ExpressQuote? {
            switch self {
            case .quote(let expressQuote):
                return expressQuote
            case .error, .notAvailable, .tooSmallAmount:
                return nil
            }
        }
    }
}
