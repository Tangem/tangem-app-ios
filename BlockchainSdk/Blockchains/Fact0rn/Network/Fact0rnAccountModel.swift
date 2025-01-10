//
//  Fact0rnAccountModel.swift
//  BlockchainSdk
//
//  Created by Alexander Skibin on 10.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct Fact0rnAccountModel {
    let addressInfo: ElectrumAddressInfo
    let pendingTransactions: [PendingTransaction]
}
