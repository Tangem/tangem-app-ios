//
//  NEARAccessKeyInfo.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 23.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct NEARAccessKeyInfo {
    let currentNonce: UInt
    let recentBlockHash: String
    let canBeUsedForTransfer: Bool
}
