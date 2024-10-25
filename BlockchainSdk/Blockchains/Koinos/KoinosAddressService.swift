//
//  KoinosAddressService.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 06.05.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BitcoinCore
import TangemSdk

struct KoinosAddressService {
    private let bitcoinLegacyAddressService: BitcoinLegacyAddressService

    init(networkParams: INetwork) {
        bitcoinLegacyAddressService = BitcoinLegacyAddressService(networkParams: networkParams)
    }
}

// MARK: - AddressProvider

extension KoinosAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        let compressedKey = try Secp256k1Key(with: publicKey.blockchainKey).compress()
        let address = try bitcoinLegacyAddressService.makeAddress(from: compressedKey).value
        return PlainAddress(value: address, publicKey: publicKey, type: addressType)
    }
}

// MARK: - AddressValidator

extension KoinosAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        bitcoinLegacyAddressService.validate(address)
    }
}
