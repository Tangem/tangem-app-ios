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
public class BitcoinCashAddressService {
    private let legacyService: BitcoinLegacyAddressService
    private let cashAddrService: CashAddrService
    
    public init(networkParams: INetwork) {
        self.legacyService = .init(networkParams: networkParams)
        self.cashAddrService = .init(networkParams: networkParams)
    }
}

// MARK: - AddressValidator

@available(iOS 13.0, *)
extension BitcoinCashAddressService: AddressValidator {
    public func validate(_ address: String) -> Bool {
        cashAddrService.validate(address) || legacyService.validate(address)
    }
}

// MARK: - AddressProvider

@available(iOS 13.0, *)
extension BitcoinCashAddressService: AddressProvider {
    public func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
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
    public func isLegacy(_ address: String) -> Bool {
        legacyService.validate(address)
    }
}
