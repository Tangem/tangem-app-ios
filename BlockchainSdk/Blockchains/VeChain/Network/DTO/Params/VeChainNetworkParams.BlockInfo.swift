//
//  VeChainNetworkParams.BlockInfo.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 20.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension VeChainNetworkParams {
    struct BlockInfo {
        enum RequestType {
            case specificWithId(String)
            case specificWithNumber(UInt)
            case latest
            case latestFinalized
        }

        let requestType: RequestType
        let isExpanded: Bool
    }
}
