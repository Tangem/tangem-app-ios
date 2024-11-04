//
//  CaspertTransactionParams.swift
//  BlockchainSdk
//
//  Created by Alexander Skibin on 04.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct CasperTransactionParams: TransactionParams {
    var memo: UInt64

    public init(memo: UInt64) {
        self.memo = memo
    }
}
