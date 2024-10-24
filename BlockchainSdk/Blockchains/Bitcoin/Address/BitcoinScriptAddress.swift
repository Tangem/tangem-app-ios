//
//  BitcoinAddress.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 26/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct BitcoinScriptAddress: Address {
	public let script: BitcoinScript
	public let value: String
    public let publicKey: Wallet.PublicKey
	public let type: AddressType
    public var localizedName: String { type.defaultLocalizedName }
    
    public init(script: BitcoinScript, value: String, publicKey: Wallet.PublicKey, type: AddressType) {
        self.script = script
        self.value = value
        self.publicKey = publicKey
        self.type = type
    }
}

