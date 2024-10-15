//
//  EthereumTransactionDataBuilder.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 13.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import Combine

public protocol EthereumTransactionDataBuilder {
    func buildForTokenTransfer(destination: String, amount: Amount) throws -> Data
    func buildForApprove(spender: String, amount: Decimal) throws -> Data
}
