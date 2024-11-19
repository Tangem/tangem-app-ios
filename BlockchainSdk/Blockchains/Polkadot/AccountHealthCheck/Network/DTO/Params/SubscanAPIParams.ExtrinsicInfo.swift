//
//  SubscanAPIParams.ExtrinsicInfo.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 21.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension SubscanAPIParams {
    struct ExtrinsicInfo: Encodable {
        let hash: String
    }
}
