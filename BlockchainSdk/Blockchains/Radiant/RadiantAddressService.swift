//
//  RadiantAddressService.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 05.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BitcoinCore

class RadiantAddressService {
    let addressAdapter = BitcoinWalletCoreAddressAdapter(coin: .bitcoinCash)
}

// MARK: - AddressValidator

extension RadiantAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        addressAdapter.validateSpecify(prefix: .p2pkh, for: address)
    }
}

// MARK: - AddressProvider

extension RadiantAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        let address = try addressAdapter.makeAddress(for: publicKey, by: .p2pkh)
        return PlainAddress(value: address.description, publicKey: publicKey, type: addressType)
    }
}
