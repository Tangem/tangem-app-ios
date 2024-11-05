//
//  CosmosTransactionParams.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 13.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct CosmosTransactionParams: TransactionParams {
    let memo: String

    public init(memo: String) {
        self.memo = memo
    }
}
