//
//  KaspaFeeMapper.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 16.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct KaspaFeeMapper {
    private let blockchain: Blockchain

    init(isTestnet: Bool) {
        blockchain = .kaspa(testnet: isTestnet)
    }

    func mapFee(mass: KaspaMassResponse, feeEstimate: KaspaFeeEstimateResponse) -> [Fee] {
        let buckets = (
            feeEstimate.lowBuckets
                + feeEstimate.normalBuckets
                + [feeEstimate.priorityBucket]
        )
        .sorted() // just in case, because it's not described in the documentation.
        .suffix(3) // select the 3 largest baskets

        let mass = Decimal(mass.mass)

        let fees = buckets.map { bucket in
            let feeRate = Decimal(bucket.feerate)
            let value = mass * feeRate / blockchain.decimalValue
            return Fee(Amount(with: blockchain, value: value))
        }

        return fees
    }
}
