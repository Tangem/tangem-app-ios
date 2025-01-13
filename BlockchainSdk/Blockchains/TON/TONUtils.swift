//
//  TONUtils.swift
//  BlockchainSdk
//
//  Created by Alexander Skibin on 09.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

struct TONUtils {
    /// Converts given amount to a uint128 with big-endian byte order.
    func jettonAmountPayload(from decimalAmount: Decimal, decimalCount: Int) throws -> Data {
        let decimalValue = decimalAmount.rounded(scale: decimalCount, roundingMode: .down)

        guard let bigUIntValue = BigUInt(decimal: decimalValue) else {
            throw WalletError.failedToBuildTx
        }

        let rawPayload = Data(bigUIntValue.serialize())

        return rawPayload
    }
}
