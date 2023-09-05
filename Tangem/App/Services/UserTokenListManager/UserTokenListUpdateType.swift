//
//  UserTokenListUpdateType.swift
//  Tangem
//
//  Created by Andrey Fedorov on 23.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import struct BlockchainSdk.Token

enum UserTokenListUpdateType {
    case append(_ entries: [StorageEntry])
    case removeBlockchain(_ blockchainNetwork: BlockchainNetwork)
    case removeToken(_ token: Token, in: BlockchainNetwork)
}
