//
//  TronTransactionDataBuilder.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 13.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol TronTransactionDataBuilder {
    func buildForApprove(spender: String, amount: Amount) throws -> Data
}
