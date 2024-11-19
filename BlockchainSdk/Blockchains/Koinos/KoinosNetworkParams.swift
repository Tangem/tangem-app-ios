//
//  KoinosNetworkParams.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 28.05.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct KoinosNetworkParams {
    let contractID: String
    let chainID: String

    init(isTestnet: Bool) {
        if isTestnet {
            contractID = KoinContractAbiConstants.ContractIDTestnet
            chainID = KoinContractAbiConstants.ChainIDTestnet
        } else {
            contractID = KoinContractAbiConstants.ContractID
            chainID = KoinContractAbiConstants.ChainID
        }
    }
}

extension KoinosNetworkParams {
    enum BalanceOf {
        static let entryPoint = 0x5c721497
    }
}

extension KoinosNetworkParams {
    enum Transfer {
        static let transactionIDPrefix = "0x1220"
        static let entryPoint: UInt32 = 0x27f576ca
    }
}

private enum KoinContractAbiConstants {
    static let ContractID = "15DJN4a8SgrbGhhGksSBASiSYjGnMU8dGL"
    static let ContractIDTestnet = "1FaSvLjQJsCJKq5ybmGsMMQs8RQYyVv8ju"
    static let ChainID = "EiBZK_GGVP0H_fXVAM3j6EAuz3-B-l3ejxRSewi7qIBfSA=="
    static let ChainIDTestnet = "EiBncD4pKRIQWco_WRqo5Q-xnXR7JuO3PtZv983mKdKHSQ=="
}
