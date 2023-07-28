//
//  WalletStubs.swift
//  Tangem
//
//  Created by Andrew Son on 28/07/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

extension Wallet {
    static let ethereumWalletStub = Wallet(
        blockchain: .ethereum(testnet: false),
        addresses: [
            .default: PlainAddress(
                value: "0x1213012890acc67bd6f731",
                publicKey: .init(
                    seedKey: Data.randomData(count: 32),
                    derivation: .ethDerivationStub
                ),
                type: .default
            ),
        ]
    )

    static let btcWalletStub = Wallet(
        blockchain: .bitcoin(testnet: false),
        addresses: [
            .default: PlainAddress(
                value: "bc1qv6qqzvca7ctp4g0rlzsz4y99n0gz4m9q5cgp59gg70d07y6ds8tq2n4f4l",
                publicKey: .init(
                    seedKey: Data(
                        hexString: "0374D0F81F42DDFE34114D533E95E6AE5FE6EA271C96F1FA505199FDC365AE9720"),
                    derivation: .btcLegacyDerivationStub
                ),
                type: .default
            ),
            .legacy: PlainAddress(
                value: "3MWJrTASt4e8CqmcEfimtaRahE81RwyGy1",
                publicKey: .init(
                    seedKey: Data(
                        hexString: "0374D0F81F42DDFE34114D533E95E6AE5FE6EA271C96F1FA505199FDC365AE9720"),
                    derivation: .btcLegacyDerivationStub
                ),
                type: .legacy
            ),
        ]
    )

    static let xrpWalletStub = Wallet(
        blockchain: .xrp(curve: .secp256k1),
        addresses: [
            .default: PlainAddress(
                value: "rNL1cRHvsiTV1uDRmXNuREVuo9Luuv6Lwt",
                publicKey: .init(
                    seedKey: Data(hexString: "0374D0F81F42DDFE34114D533E95E6AE5FE6EA271C96F1FA505199FDC365AE9720"),
                    derivation: .btcSegwitDerivationStub
                ),
                type: .default
            ),
        ]
    )
}
