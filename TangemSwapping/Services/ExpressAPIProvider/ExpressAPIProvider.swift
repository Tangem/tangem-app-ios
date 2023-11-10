//
//  ExpressAPIProvider.swift
//  TangemSwapping
//
//  Created by Sergey Balashov on 08.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol ExpressAPIProvider {
    func assets(with filter: [ExpressCurrency]) async throws -> [ExpressAsset]
    func pairs(from: [ExpressCurrency], to: [ExpressCurrency]) async throws -> [ExpressPair]

    func providers() async throws -> [ExpressProvider]
    func exchangeQuote(item: ExpressSwappableItem) async throws -> ExpressQuote
    func exchangeData(item: ExpressSwappableItem, destinationAddress: String) async throws -> ExpressTransactionData
    func exchangeResult(transactionId: String) async throws -> ExpressTransaction
}
