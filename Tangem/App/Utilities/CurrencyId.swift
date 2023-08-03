//
//  CurrencyId.swift
//  Tangem
//
//  Created by Andrey Chukavin on 03.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

enum CurrencyId {
    static func id(for amount: Amount, blockchainNetwork: BlockchainNetwork) -> String? {
        switch amount.type {
        case .token(let token):
            return token.id
        default:
            return blockchainNetwork.blockchain.currencyId
        }
    }
}
