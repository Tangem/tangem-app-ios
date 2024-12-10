//
//  Fact0rnAddressService.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 11.12.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

struct Fact0rnAddressService {}

// MARK: - AddressProvider

extension Fact0rnAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        fatalError("Not implemented")
    }
}

// MARK: - AddressValidator

extension Fact0rnAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        fatalError("Not implemented")
    }
}
