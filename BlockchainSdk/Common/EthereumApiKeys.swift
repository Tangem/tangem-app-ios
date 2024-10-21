//
//  EthereumApiKeys.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 23.12.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct EthereumApiKeys {
    let infuraProjectId: String
    let nowNodesApiKey: String
    let getBlockApiKeys: [Blockchain: String]
    let quickNodeBscCredentials: BlockchainSdkConfig.QuickNodeCredentials
}
