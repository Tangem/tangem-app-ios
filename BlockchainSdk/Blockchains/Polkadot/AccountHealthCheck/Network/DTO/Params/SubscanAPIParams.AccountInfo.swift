//
//  SubscanAPIParams.AccountInfo.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 21.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension SubscanAPIParams {
    struct AccountInfo: Encodable {
        /// The address of the account.
        let key: String
    }
}
