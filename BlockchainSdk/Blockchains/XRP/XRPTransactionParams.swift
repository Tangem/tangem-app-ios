//
//  XRPTransactionParams.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 23.11.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct XRPTransactionParams: TransactionParams {
    public var destinationTag: UInt32?
    
    public init(destinationTag: UInt32? = nil) {
        self.destinationTag = destinationTag
    }
}
