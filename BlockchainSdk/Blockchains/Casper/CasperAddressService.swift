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
        guard let prefixAddresss = CasperConstants.getPrefix(by: curve) else {
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
        let isCorrectEd25519Address = address.count == CasperConstants.lengthED25519 && address.hasPrefix(CasperConstants.prefixED25519)
        let isCorrectSecp256k1Address = address.count == CasperConstants.lengthSECP256K1 && address.hasPrefix(CasperConstants.prefixSECP256K1)

        guard isCorrectEd25519Address || isCorrectSecp256k1Address else {
            return false
        }

        if address.isSameCase() {
            return true
        }

        do {
            return try address == CasperAddressUtils().checksum(input: Data(hexString: address))
        } catch {
            return false
        }
    }
}

// MARK: - Constants

extension CasperAddressService {
    enum Error: LocalizedError {
        case unsupportedAddressPrefix
    }
}

// MARK: - Helpers

private extension String {
    func isSameCase() -> Bool {
        lowercased() == self || uppercased() == self
    }
}
