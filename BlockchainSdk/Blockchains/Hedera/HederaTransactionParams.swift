//
//  HederaTransactionParams.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 05.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct HederaTransactionParams: TransactionParams {
    let memo: String

    public init(memo: String) {
        self.memo = memo
    }
}
