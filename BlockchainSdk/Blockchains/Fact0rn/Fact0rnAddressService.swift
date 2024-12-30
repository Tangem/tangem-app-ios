//
//  Fact0rnAddressService.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 11.12.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BitcoinCore

// TODO: [Fact0rn] Implement AddressService
// https://tangem.atlassian.net/browse/IOS-8756
struct Fact0rnAddressService {
    let bech32: BitcoinBech32AddressService

    init() {
        bech32 = BitcoinBech32AddressService(networkParams: Fact0rnMainNetworkParams())
    }
}

// MARK: - AddressProvider

extension Fact0rnAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        let bech32AddressString = try bech32.makeAddress(from: publicKey.blockchainKey).value
        return PlainAddress(value: bech32AddressString, publicKey: publicKey, type: addressType)
    }
}

// MARK: - AddressValidator

extension Fact0rnAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        bech32.validate(address)
    }
}
