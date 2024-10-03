//
//  ExpressManagerError.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 10.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum ExpressManagerError: String, LocalizedError {
    case amountNotFound
    case contractAddressNotFound
    case availablePairNotFound
    case pairNotFound
    case selectedProviderNotFound
    case quotesNotFound
    case availableQuotesForProviderNotFound
    case objectReleased

    public var errorDescription: String? {
        rawValue
    }
}
