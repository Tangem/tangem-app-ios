//
// SuiCoinObject.swift
// BlockchainSdk
//
// Created by Sergei Iakovlev on 17.09.2024
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct SuiCoinObject {
    let coinType: String
    let coinObjectId: String
    let version: UInt64
    let digest: String
    let balance: Decimal

    static func from(_ response: SuiGetCoins.Coin) -> Self? {
        guard let version = Decimal(stringValue: response.version)?.uint64Value,
              let balance = Decimal(stringValue: response.balance) else {
            return nil
        }

        return SuiCoinObject(
            coinType: response.coinType,
            coinObjectId: response.coinObjectId,
            version: version,
            digest: response.digest,
            balance: balance
        )
    }
}
