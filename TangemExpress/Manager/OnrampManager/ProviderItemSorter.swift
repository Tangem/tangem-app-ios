//
//  ProviderItemSorter.swift
//  TangemApp
//
//  Created by Sergey Balashov on 16.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct ProviderItemSorter {
    func sort(lhs: OnrampProvider, rhs: OnrampProvider) -> Bool {
        switch (lhs.state, rhs.state) {
        case (.loaded(let lhsQuote), .loaded(let rhsQuote)):
            return lhsQuote.expectedAmount > rhsQuote.expectedAmount
        // All cases which is not `loaded` have to be ordered after
        case (_, .loaded):
            return false
        // All cases which is `loaded` have to be ordered before `rhs`
        // Exclude case where `rhs == .loaded`. This case processed above
        case (.loaded, _):
            return true
        case (.restriction(let lhsRestriction), .restriction(let rhsRestriction)):
            let lhsDiff = (lhs.amount ?? 0) - (lhsRestriction.amount ?? 0)
            let rhsDiff = (rhs.amount ?? 0) - (rhsRestriction.amount ?? 0)
            return abs(lhsDiff) > abs(rhsDiff)
        case (.restriction, _):
            return true
        case (_, .restriction):
            return false
        default:
            return false
        }
    }
}
