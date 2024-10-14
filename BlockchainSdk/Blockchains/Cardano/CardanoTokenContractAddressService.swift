//
//  CardanoTokenContractAddressService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 01.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public struct CardanoTokenContractAddressService {

    public init() {}
    
    /// Convert to single format of cardano token address
    /// https://cips.cardano.org/cip/CIP-14
    /// - Parameters:
    ///   - address: token contract address (PolicyID or Fingerprint or AssetID)
    ///   - symbol: token symbol, aka asset name
    /// - Returns: fingerprint
    public func convertToFingerprint(address: String, symbol: String?) throws -> String {
        let addressType = try parseAddressType(address)

        guard addressType != .fingerprint else {
            return address
        }

        let addressData = getAddressData(from: address, symbol: symbol, addressType: addressType)

        guard let hash = addressData.hashBlake2b(outputLength: Constants.hashSize) else {
            throw Error.hashingFailed
        }

        let encoded = Bech32().encode(Constants.hrp, values: hash)

        if encoded.isEmpty {
            throw Error.encodingFailed
        }

        return encoded
    }

    private func getAddressData(from address: String, symbol: String?, addressType: ContractAddressType) -> Data {
        guard let symbol,
              addressType == .policyID,
              let suffix = symbol.data(using: .utf8)?.hexString else {
            return Data(hexString: address)
        }

        return Data(hexString: address + suffix)
    }

    @discardableResult
    private func parseAddressType(_ address: String) throws -> ContractAddressType {
        if let decoded = try? Bech32().decode(address) {
            if decoded.hrp == Constants.hrp {
                return .fingerprint
            } else {
                throw Error.invalidAddress
            }
        }

        guard address.isValidHex else {
            throw Error.invalidAddress
        }

        let addressLength = address.count

        if addressLength == Constants.policyIDLength {
            return .policyID
        }

        if addressLength > Constants.policyIDLength {
            return .assetID
        }

        throw Error.invalidAddress
    }
}

// MARK: - AddressValidator

extension CardanoTokenContractAddressService: AddressValidator {
    public func validate(_ address: String) -> Bool {
        do {
            try parseAddressType(address)
            return true
        }
        catch {
            return false
        }
    }
}

// MARK: - ContractAddressType

extension CardanoTokenContractAddressService {
    enum ContractAddressType {
        case policyID
        case assetID
        case fingerprint
    }
}

// MARK: - Error

extension CardanoTokenContractAddressService {
    enum Error: String, LocalizedError {
        case invalidAddress
        case hashingFailed
        case encodingFailed

        var errorDescription: String? { rawValue }
    }
}

// MARK: - Constants

private extension CardanoTokenContractAddressService {
    enum Constants {
        static let hrp = "asset"
        static let hashSize = 20
        static let policyIDLength = 56
    }
}
