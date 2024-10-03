//
//  BlockchainAccountCreateResult.swift
//  Tangem
//
//  Created by Andrey Fedorov on 14.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct BlockchainAccountCreateResult: Decodable {
    struct AccountData: Decodable {
        let accountId: String
        let walletPublicKey: String
    }

    let data: AccountData
}
