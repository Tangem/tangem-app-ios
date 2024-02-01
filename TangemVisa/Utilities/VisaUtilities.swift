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
        testnetUSDTtoken
    }

    public var visaBlockchain: Blockchain {
        .polygon(testnet: true)
    }
}

internal extension VisaUtilities {
    var TangemBridgeProcessorAddresses: [String] {
        [
            "0x7cb2513e419c8fcbc731f19c85fe1c61642fed38",
            "0xfb1ca6456edcce2c2c6e1ac4fccc32c0ac88d86e",
        ]
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
}
