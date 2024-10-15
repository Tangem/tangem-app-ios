//
//  BlockBookTarget.AddressRequestParameters.FilterType+.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 28.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension BlockBookTarget.AddressRequestParameters.FilterType {
    init(amountType: Amount.AmountType) {
        switch amountType {
        case .coin, .reserve, .feeResource:
            self = .coin
        case .token(let token):
            self = .contract(token.contractAddress)
        }
    }
}
