//
//  StellarTransactionParams.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 23.11.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import stellarsdk

public typealias StellarMemo = Memo

public struct StellarTransactionParams: TransactionParams {
    var memo: StellarMemo?

    public init(memo: StellarMemo? = nil) {
        self.memo = memo
    }
}
