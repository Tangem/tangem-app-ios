//
//  FilecoinFeeParameters.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 30.08.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BigInt

struct FilecoinFeeParameters: FeeParameters {
    let gasLimit: Int64
    let gasFeeCap: BigUInt
    let gasPremium: BigUInt
}
