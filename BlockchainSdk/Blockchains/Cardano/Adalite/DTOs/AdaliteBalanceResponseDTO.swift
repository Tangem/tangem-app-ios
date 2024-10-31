//
//  AdaliteBalanceResponseDTO.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 31.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct AdaliteBalanceResponseDTO: Decodable {
    let caBalance: CaBalance
    let caTxNum: Int
    let caAddress: String
    let caType: String
    let caTxList: [CaTx]
}

extension AdaliteBalanceResponseDTO {
    struct CaBalance: Decodable {
        let getTokens: [AdaliteTokenDTO]
        let getCoin: String
    }

    struct CaTx: Decodable {
        let ctbId: String
    }
}
