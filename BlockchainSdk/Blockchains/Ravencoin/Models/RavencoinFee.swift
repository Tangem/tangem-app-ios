//
//  RavencoinFee.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 04.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct RavencoinFee {
    struct Request: Encodable {
        let nbBlocks: Int
        let mode: RavencoinFeeMode
        
        init(nbBlocks: Int, mode: RavencoinFeeMode = .economical) {
            self.nbBlocks = nbBlocks
            self.mode = mode
        }
    }
    
    enum RavencoinFeeMode: String, Encodable {
        case economical
        case conservative
    }
}
