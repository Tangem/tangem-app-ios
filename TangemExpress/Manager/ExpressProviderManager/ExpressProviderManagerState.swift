//
//  ExpressProviderManagerState.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 11.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum ExpressProviderManagerState {
    case idle
    case error(Error, quote: ExpressQuote?)
    case restriction(_ restriction: ExpressRestriction, quote: ExpressQuote?)

    case permissionRequired(ExpressManagerState.PermissionRequired)
    case preview(ExpressManagerState.PreviewCEX)
    case ready(ExpressManagerState.Ready)

    public var isError: Bool {
        switch self {
        case .idle, .permissionRequired, .restriction, .preview, .ready:
            return false
        case .error:
            return true
        }
    }

    public var quote: ExpressQuote? {
        switch self {
        case .idle:
            return nil
        case .error(_, let quote):
            return quote
        case .restriction(_, let quote):
            return quote
        case .permissionRequired(let state):
            return state.quote
        case .preview(let state):
            return state.quote
        case .ready(let state):
            return state.quote
        }
    }
}

extension ExpressProviderManagerState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .idle:
            return "idle"
        case .error(let error, let quote):
            return "error \(error) quote \(String(describing: quote))"
        case .restriction(let restriction, let quote):
            return "restriction \(restriction) quote \(String(describing: quote))"
        case .permissionRequired(let permissionRequired):
            return "permissionRequired quote \(permissionRequired.quote)"
        case .preview(let previewCEX):
            return "previewCEX subtractFee: \(previewCEX.subtractFee) fee: \(previewCEX.fee) quote \(previewCEX.quote)"
        case .ready(let ready):
            return "ready fee: \(ready.fee) quote \(ready.quote)"
        }
    }
}
