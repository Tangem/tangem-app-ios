//
//  HederaCreatedAccount.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 19.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct HederaCreatedAccount: CreatedAccount {
    let accountId: String

    public init(accountId: String) {
        self.accountId = accountId
    }
}
