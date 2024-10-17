//
//  XRPTransactionParams.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 23.11.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

struct XRPTransactionParams: TransactionParams {
    var destinationTag: UInt32?
    
    init(destinationTag: UInt32? = nil) {
        self.destinationTag = destinationTag
    }
}
