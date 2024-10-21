//
//  BinanceTransactionParams.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 20.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public struct BinanceTransactionParams: TransactionParams {
    public var memo: String?
    
    public init(memo: String? = nil) {
        self.memo = memo
    }
}
