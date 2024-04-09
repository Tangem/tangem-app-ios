//
//  VisaUtilities.swift
//  TangemVisa
//
//  Created by Andrew Son on 18/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

public struct VisaUtilities {
    public init() {}

    public var visaToken: Token {
        visaBlockchain.isTestnet ? testnetUSDTtoken : usdtToken
    }

    public var visaBlockchain: Blockchain {
        .polygon(testnet: true)
    }
}

internal extension VisaUtilities {
    var registryAddress: String {
        if visaBlockchain.isTestnet {
            return "0x3f4ae01073d1a9d5a92315fe118e57d1cdec7c44"
        }

        return "0xa7299243262087462a040c743ab6c8649ebcc1fe"
    }
}

private extension VisaUtilities {
    private var testnetUSDTtoken: Token {
        .init(
            name: "Tether",
            symbol: "USDT",
            contractAddress: "0x1A826Dfe31421151b3E7F2e4887a00070999150f",
            decimalCount: 18,
            id: "tether"
        )
    }

    private var usdtToken: Token {
        .init(
            name: "Tether",
            symbol: "USDT",
            contractAddress: "0xc2132d05d31c914a87c6611c10748aeb04b58e8f",
            decimalCount: 6,
            id: "tether"
        )
    }
}
