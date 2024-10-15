//
//  XrpResponse.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 10.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

struct XRPFeeResponse {
    let min: Decimal
    let normal: Decimal
    let max: Decimal
}

struct XrpInfoResponse {
    let balance: Decimal
    let sequence: Int
    let unconfirmedBalance: Decimal
    let reserve: Decimal
}
