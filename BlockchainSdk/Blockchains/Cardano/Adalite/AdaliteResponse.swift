//
//  AdaliteResponse.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 08.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct AdaliteUnspentOutput {
    let id: String
    let index: Int
}

public struct AdaliteBalanceResponse {
    let transactions: [String]
}
