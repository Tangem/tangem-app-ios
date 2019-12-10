//
//  BitcoinNetwork.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 10.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

struct BtcFee {
    let minimalKb: Decimal
    let normalKb: Decimal
    let priorityKb: Decimal
}

struct BtcResponse {
    let balance: Decimal
    let unconfirmed_balance: Int
    let txrefs: [BtcTx]
}

struct BtcTx {
    let tx_hash: String
    let tx_output_n: Int
    let value: UInt64
}
