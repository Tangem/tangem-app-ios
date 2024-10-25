//
//  RavencoinWalletInfo.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 03.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct RavencoinWalletInfo: Decodable {
    let address: String

    let balance: Decimal?
    let balanceSatoshi: Decimal?

    let totalReceived: Decimal?
    let totalReceivedSatoshi: Decimal?

    let totalSent: Decimal?
    let totalSentSatoshi: Decimal?

    let unconfirmedBalance: Decimal
    let unconfirmedBalanceSatoshi: Decimal

    let unconfirmedTxApperances: Int
    let txApperances: Int

    let transactions: [String]

    enum CodingKeys: String, CodingKey {
        case address = "addrStr"

        case balance
        case balanceSatoshi = "balanceSat"

        case totalReceived
        case totalReceivedSatoshi = "totalReceivedSat"

        case totalSent
        case totalSentSatoshi = "totalSentSat"

        case unconfirmedBalance
        case unconfirmedBalanceSatoshi = "unconfirmedBalanceSat"

        case unconfirmedTxApperances
        case txApperances
        case transactions
    }
}
