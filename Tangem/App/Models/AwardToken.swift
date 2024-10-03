//
//  AwardToken.swift
//  Tangem
//
//  Created by Andrey Chukavin on 14.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct AwardToken: Decodable {
    let id: String
    let name: String
    let symbol: String
    let networkId: String
    let contractAddress: String?
    let decimalCount: Int?
}

extension AwardToken {
    var storageToken: Token? {
        guard
            let contractAddress = contractAddress,
            let decimalCount = decimalCount
        else {
            return nil
        }

        return Token(
            name: name,
            symbol: symbol,
            contractAddress: contractAddress,
            decimalCount: decimalCount,
            id: id
        )
    }
}
