//
//  ExpressManagerState.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 10.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum ExpressManagerState {
    case idle

    // Final states
    // Restrictions -> Notifications
    // Will be returned after the quote request
    case restriction(_ restriction: ExpressRestriction, quote: ExpressQuote?)

    // Will be returned if there's not enough allowance
    case permissionRequired(PermissionRequired)

    // Will be returned for a CEX provider
    case previewCEX(PreviewCEX)

    // Will be returned after the swap request
    case ready(Ready)

    public var quote: ExpressQuote? {
        switch self {
        case .idle:
            return nil
        case .restriction(_, let quote):
            return quote
        case .permissionRequired(let permissionRequired):
            return permissionRequired.quote
        case .previewCEX(let previewCEX):
            return previewCEX.quote
        case .ready(let ready):
            return ready.quote
        }
    }
}

public extension ExpressManagerState {
    struct PermissionRequired {
        public let policy: ExpressApprovePolicy
        public let data: ApproveTransactionData
        public let quote: ExpressQuote
    }

    struct PreviewCEX {
        public let fee: ExpressFee
        public let subtractFee: Decimal
        public let quote: ExpressQuote
    }

    struct Ready {
        public let fee: ExpressFee
        public let data: ExpressTransactionData
        public let quote: ExpressQuote
    }
}
