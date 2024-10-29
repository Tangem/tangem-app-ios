//
//  CasperNetworkRequest.QueryBalance.swift
//  BlockchainSdk
//
//  Created by Alexander Skibin on 29.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension CasperNetworkRequest {
    struct QueryBalance: Encodable {
        let purseIdentifier: PurseIdentifier
    }
    
    struct PurseIdentifier: Encodable {
        let mainPurseUnderPublicKey: String
    }
}
