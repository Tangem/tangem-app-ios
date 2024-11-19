//
//  DecimalAddressService.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 15.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct DecimalAddressService {
    // MARK: - Private Properties

    private let ethereumAddressService = AddressServiceFactory(blockchain: .ethereum(testnet: false)).makeAddressService()
    private let converter = DecimalAddressConverter()
}

// MARK: - AddressProvider protocol conformance

extension DecimalAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        let ethAddress = try ethereumAddressService.makeAddress(for: publicKey, with: .default).value

        switch addressType {
        case .default:
            // If need to convert address to decimal native type
            let decimalAddress = try converter.convertToDecimalAddress(ethAddress)
            return DecimalPlainAddress(value: decimalAddress, publicKey: publicKey, type: addressType)
        case .legacy:
            return DecimalPlainAddress(value: ethAddress, publicKey: publicKey, type: addressType)
        }
    }
}

// MARK: - AddressValidator protocol conformance

extension DecimalAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        guard let dscAddress = try? converter.convertToETHAddress(address) else {
            return false
        }

        return ethereumAddressService.validate(dscAddress)
    }
}
