//
//  AdaliteBaseResponseDTO.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 31.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct AdaliteBaseResponseDTO<Left: Decodable, Right: Decodable>: Decodable {
    let right: Right?
    let left: Left?
    
    enum CodingKeys: String, CodingKey {
        case right = "Right"
        case left = "Left"
    }
}
