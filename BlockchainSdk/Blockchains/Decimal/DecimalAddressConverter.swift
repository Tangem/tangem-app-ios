//
//  DecimalAddressConverter.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 15.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/*
 Decimal Blockchain Address - d01clhamkvxw8ur9afuzxqhuvsrzelcl0x25j4asd
 DSC Address - 0xc7efddd98671f832f53c11817e3203167f8fbasd
 Legacy Address - dx1fv0m65st02p0z93xxarsd6g4ydltg8crm78hkv no use
 */

struct DecimalAddressConverter: EthereumAddressConverter {

    // MARK: - Private Properties
    
    private let bech32 = Bech32()
    
    // MARK: - Implementation
    
    func convertToDecimalAddress(_ address: String) throws -> String {
        if address.lowercased().hasPrefix(Constants.addressPrefix) || address.lowercased().hasPrefix(Constants.legacyAddressPrefix) {
            return address
        }

        let addressBytes = Data(hexString: address)

        return bech32.encode(Constants.addressPrefix, values: addressBytes)
    }

    func convertToETHAddress(_ address: String) throws -> String {
        if address.hasHexPrefix() {
            return address
        }
        
        let decodeValue = try bech32.decode(address)

        let convertedAddressBytes = try bech32.convertBits(
            data: decodeValue.checksum.bytes,
            fromBits: 5,
            toBits: 8,
            pad: false
        )

        return convertedAddressBytes.toHexString().addHexPrefix()
    }
}

extension DecimalAddressConverter {
    enum Constants {
        static let addressPrefix = "d0"
        static let legacyAddressPrefix = "dx"
    }
}
