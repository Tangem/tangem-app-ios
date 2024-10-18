//
//  BitcoinAddress.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 26/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

struct BitcoinScriptAddress: Address {
    let script: BitcoinScript
    let value: String
    let publicKey: Wallet.PublicKey
    let type: AddressType
    var localizedName: String { type.defaultLocalizedName }

    init(script: BitcoinScript, value: String, publicKey: Wallet.PublicKey, type: AddressType) {
        self.script = script
        self.value = value
        self.publicKey = publicKey
        self.type = type
    }
}
