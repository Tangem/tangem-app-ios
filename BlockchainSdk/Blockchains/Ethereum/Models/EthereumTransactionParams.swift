//
//  EthereumTransactionParams.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 12/04/21.
//

import Foundation
import BigInt

public struct EthereumTransactionParams: TransactionParams {
    let data: Data?
    let nonce: Int?

    public init(data: Data? = nil, nonce: Int? = nil) {
        self.data = data
        self.nonce = nonce
    }
}

extension EthereumTransactionParams {
    func with(nonce: Int) -> EthereumTransactionParams {
        EthereumTransactionParams(data: data, nonce: nonce)
    }
}
