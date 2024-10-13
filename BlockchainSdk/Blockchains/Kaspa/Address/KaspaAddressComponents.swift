//
//  KaspaAddress.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 17.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BitcoinCore

struct KaspaAddressComponents {
    let prefix: String
    let type: KaspaAddressType
    let hash: Data
}

extension KaspaAddressComponents {
    enum KaspaAddressType: UInt8 {
        case P2PK_Schnorr = 0
        case P2PK_ECDSA = 1
        case P2SH = 8
    }
}
