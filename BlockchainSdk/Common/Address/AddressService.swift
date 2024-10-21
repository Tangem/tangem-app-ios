//
//  AddressService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 20.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public typealias AddressService = AddressProvider & AddressValidator

public protocol AddressValidator {
    func validate(_ address: String) -> Bool
}

public protocol AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address
}

public protocol AddressAdditionalFieldService {
    func canEmbedAdditionalField(into address: String) -> Bool
}

// A convenient extension for using a raw public key
public extension AddressProvider {
    func makeAddress(from publicKey: Data, type: AddressType = .default) throws -> Address {
        try makeAddress(for: Wallet.PublicKey(seedKey: publicKey, derivationType: .none), with: type)
    }
}
