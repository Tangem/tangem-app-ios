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
    case notEnoughAmountToSubtractFee

    public var errorDescription: String? {
        switch self {
        case .amountNotFound: "Amount not found"
        case .contractAddressNotFound: "Contract address not found"
        case .availablePairNotFound: "Available pair not found"
        case .pairNotFound: "Pair not found"
        case .selectedProviderNotFound: "Selected provider not found"
        case .quotesNotFound: "Quotes not found"
        case .availableQuotesForProviderNotFound: "Available quotes for provider not found"
        case .objectReleased: "Object released"
        case .notEnoughAmountToSubtractFee: "Not enough amount to subtract fee"
        }
    }
}
