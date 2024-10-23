//
//  CasperAddressService.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 22.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public struct CasperAddressService {
    // MARK: - Private Properties
    
    private let curve: EllipticCurve
    
    // MARK: - Init
    
    init(curve: EllipticCurve) {
        self.curve = curve
    }
}

// MARK: - AddressProvider

extension CasperAddressService: AddressProvider {
    public func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        guard let prefixAddresss = Constants.getAddressPrefix(curve: curve) else {
            throw Error.unsupportedAddressPrefix
        }
        
        let addressBytes = Data(hexString: prefixAddresss) + publicKey.blockchainKey
        let address = try CasperAddressUtils().checksum(input: addressBytes)
        return PlainAddress(value: address, publicKey: publicKey, type: addressType)
    }
}

// MARK: - AddressValidator

extension CasperAddressService: AddressValidator {
    public func validate(_ address: String) -> Bool {
        return false
    }
}

// MARK: - Constants

extension CasperAddressService {
    enum Constants {
        // ED25519
        static let prefixED25519 = "01"
        static let lengthED25519 = 66
        
        // SECP256K1
        static let prefixSECP256K1 = "02"
        static let lengthSECP256K1 = 68
        
        static func getAddressPrefix(curve: EllipticCurve) -> String? {
            switch curve {
            case .ed25519, .ed25519_slip0010:
                return CasperAddressService.Constants.prefixED25519
            case .secp256k1:
                return CasperAddressService.Constants.prefixSECP256K1
            default:
                // Any curves not supported or will be added in the future
                return nil
            }
        }
    }
    
    enum Error: LocalizedError {
        case unsupportedAddressPrefix
    }
}
