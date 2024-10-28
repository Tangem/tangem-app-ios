//
//  BitcoinCashAddressService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 14.02.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BitcoinCore

@available(iOS 13.0, *)
class BitcoinCashAddressService {
    private let legacyService: BitcoinLegacyAddressService
    private let cashAddrService: CashAddrService

    init(networkParams: INetwork) {
        legacyService = .init(networkParams: networkParams)
        cashAddrService = .init(networkParams: networkParams)
    }
}

// MARK: - AddressValidator

@available(iOS 13.0, *)
extension BitcoinCashAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        cashAddrService.validate(address) || legacyService.validate(address)
    }
}

// MARK: - AddressProvider

@available(iOS 13.0, *)
extension BitcoinCashAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        switch addressType {
        case .default:
            let address = try cashAddrService.makeAddress(from: publicKey.blockchainKey)
            return PlainAddress(value: address, publicKey: publicKey, type: addressType)
        case .legacy:
            let compressedKey = try Secp256k1Key(with: publicKey.blockchainKey).compress()
            let address = try legacyService.makeAddress(from: compressedKey).value
            return PlainAddress(value: address, publicKey: publicKey, type: addressType)
        }
    }
}

extension BitcoinCashAddressService {
    func isLegacy(_ address: String) -> Bool {
        legacyService.validate(address)
    }
}
