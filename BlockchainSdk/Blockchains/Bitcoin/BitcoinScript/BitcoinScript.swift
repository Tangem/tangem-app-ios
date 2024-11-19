//
//  BitcoinScript.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 28.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct BitcoinScript {
    let chunks: [BitcoinScriptChunk]
    let data: Data
}
