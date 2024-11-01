//
//  CasperTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Alexander Skibin on 31.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BigInt
import TangemSdk

final class CasperTransactionBuilder {
    
    func buildForSign(transaction: Transaction) throws -> Data {
        Data()
    }
    
    func buildForSend(transaction: Transaction, signature: Data) throws -> Data {
        Data()
    }
    
}

// MARK: - Private Implentation

private extension CasperTransactionBuilder {}

private extension CasperTransactionBuilder {
    enum Constants {
        static let DEFAULT_TTL_FORMATTED = "30m"
        static let DEFAULT_TTL_MILLIS: UInt64 = 1800000
        static let DEFAULT_GAS_PRICE: UInt64 = 1
    }
}
