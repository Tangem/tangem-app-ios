//
//  ICPTransactionParams.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 01.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct ICPTransactionParams: TransactionParams {
    public var memo: UInt64

    public init(memo: UInt64) {
        self.memo = memo
    }
}
