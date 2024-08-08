//
//  StakingMapper.swift
//  Tangem
//
//  Created by Alexander Osokin on 08.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemStaking

struct StakingMapper {
    // TODO: get fee, amount and source address
    func mapToStakeKitTransaction(_ transaction: StakingTransactionInfo) -> StakeKitTransaction {
        let stakeKitTransaction = StakeKitTransaction(
            amount: Amount(type: .coin, currencySymbol: "", value: 0, decimals: 0),
            fee: Fee(Amount(type: .coin, currencySymbol: "", value: 0, decimals: 0)),
            sourceAddress: "",
            unsignedData: transaction.unsignedTransactionData
        )

        return stakeKitTransaction
    }
}
