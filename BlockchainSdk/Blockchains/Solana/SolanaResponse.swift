//
//  SolanaResponse.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 18.01.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift

struct SolanaAccountInfoResponse {
    let balance: Decimal
    let accountExists: Bool
    let tokensByMint: [String: SolanaTokenAccountInfoResponse]
    let mainAccountRentExemption: Decimal
}

struct SolanaMainAccountInfoResponse {
    let balance: Lamports
    let accountExists: Bool
    let rentExemption: Decimal
}

struct SolanaTokenAccountInfoResponse {
    let address: String
    let mint: String
    let balance: Decimal
    let space: UInt64?
}
