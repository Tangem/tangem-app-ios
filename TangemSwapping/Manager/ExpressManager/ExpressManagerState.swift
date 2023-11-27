//
//  ExpressManagerState.swift
//  TangemSwapping
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
    case restriction(ExpressManagerRestriction, quote: ExpectedQuote?)

    // Will be returned for a CEX provider
    case previewCEX(quote: ExpectedQuote)

    // Will be returned after the swap request
    case ready(data: ExpressTransactionData, quote: ExpectedQuote)
}
