//
//  EthereumTransactionSigner.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 08.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine

public protocol EthereumTransactionSigner: AnyObject {
    /// Build and sign transaction
    /// - Parameters:
    /// - Returns: The hex of the raw transaction ready to be sent over the network
    func sign(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<String, Error>
}
