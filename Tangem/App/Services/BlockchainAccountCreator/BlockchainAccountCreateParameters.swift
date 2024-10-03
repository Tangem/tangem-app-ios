//
//  BlockchainAccountCreateParameters.swift
//  Tangem
//
//  Created by Andrey Fedorov on 14.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct BlockchainAccountCreateParameters: Encodable {
    let networkId: String
    let walletPublicKey: String
}
