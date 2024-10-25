//
//  AdaliteTokenDTO.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 01.06.2023.
//

import Foundation

struct AdaliteTokenDTO: Decodable {
    let assetName: String
    let quantity: String
    let policyId: String
}
