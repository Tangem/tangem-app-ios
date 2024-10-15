//
//  AptosAddressService.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 02.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore

public struct AptosCoreAddressService {
    private let walletCoreAddressService = WalletCoreAddressService(coin: .aptos)
    
    private func isStandardLength(for address: String) -> Bool {
        return address.removeHexPrefix().count == Constants.aptosHexAddressLength
    }
    
    private func insertNonsignificantZero(for address: String) -> String {
        let addressWithoutPrefix = address.removeHexPrefix()
        
        let addressWithZeroBuffer = addressWithoutPrefix.leftPadding(toLength: Constants.aptosHexAddressLength, withPad: Constants.nonSignificationZero)
        let nonsignificantAddress = addressWithZeroBuffer.addHexPrefix()
        
        return nonsignificantAddress
    }
}

// MARK: - AddressProvider

extension AptosCoreAddressService: AddressProvider {
    public func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        let address = try walletCoreAddressService.makeAddress(for: publicKey, with: addressType)
        
        if isStandardLength(for: address.value) {
            return address
        } else {
            let nonsignificantAddress = insertNonsignificantZero(for: address.value)
            return PlainAddress(value: nonsignificantAddress, publicKey: publicKey, type: addressType)
        }
    }
}

// MARK: - AddressValidator

extension AptosCoreAddressService: AddressValidator {
    public func validate(_ address: String) -> Bool {
        return walletCoreAddressService.validate(address)
    }
}

// MARK: - Constants

extension AptosCoreAddressService {
    enum Constants {
        static let aptosHexAddressLength = 64
        static let nonSignificationZero: Character = "0"
    }
}
