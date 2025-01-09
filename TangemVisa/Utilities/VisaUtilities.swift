//
//  VisaUtilities.swift
//  TangemVisa
//
//  Created by Andrew Son on 18/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

public struct VisaUtilities {
    private let isTestnet: Bool

    public init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }

    public var visaBatches: [String] {
        [
            "AE05",
        ]
    }

    public var mandatoryCurve: EllipticCurve {
        .secp256k1
    }

    public var tokenId: String {
        "tether"
    }

    public var visaCardDerivationPath: DerivationPath? {
        visaBlockchain.derivationPath(for: .v3)
    }

    public var mockToken: Token {
        .init(
            name: "Tether",
            symbol: "USDT",
            contractAddress: "0x1A826Dfe31421151b3E7F2e4887a00070999150f",
            decimalCount: 18,
            id: tokenId
        )
    }

    public var visaBlockchain: Blockchain {
        .polygon(testnet: isTestnet)
    }

    public var addressService: AddressService {
        AddressServiceFactory(blockchain: visaBlockchain).makeAddressService()
    }

    public func visaDefaultDerivationPath(style: DerivationStyle) -> DerivationPath? {
        visaBlockchain.derivationPath(for: style)
    }

    public func isVisaCard(_ card: Card) -> Bool {
        return isVisaCard(firmwareVersion: card.firmwareVersion, batchId: card.batchId)
    }

    public func isVisaCard(firmwareVersion: FirmwareVersion, batchId: String) -> Bool {
        return FirmwareVersion.visaRange.contains(firmwareVersion.doubleValue)
            && visaBatches.contains(batchId)
    }
}
