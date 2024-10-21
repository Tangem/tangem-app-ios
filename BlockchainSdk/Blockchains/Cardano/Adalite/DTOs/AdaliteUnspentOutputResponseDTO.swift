//
//  AdaliteUnspentOutputResponseDTO.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 31.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct AdaliteUnspentOutputResponseDTO: Decodable {
    let cuId: String
    let tag: String
    let cuCoins: CuCoins
    let cuAddress: String
    let cuOutIndex: UInt64
}

extension AdaliteUnspentOutputResponseDTO {
    struct CuCoins: Decodable {
        let getCoin: String
        let getTokens: [AdaliteTokenDTO]
    }
}
